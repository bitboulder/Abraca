/**
 * Abraca, an XMMS2 client.
 * Copyright (C) 2008-2013 Abraca Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

using GLib;

namespace Abraca {
	public class FilterModel : Gtk.ListStore, Gtk.TreeModel {
		/* Metadata resolve status */

		enum Status {
			UNRESOLVED,
			RESOLVING,
			RESOLVED
		}

		public enum Column {
			STATUS,
			ID
		}

		/* TODO: This should be a property, not just a member variable */
		public string[] dynamic_columns;

		/* Map medialib id to row */
		private Gee.Map<int,Gtk.TreeRowReference> pos_map = new Gee.HashMap<int,Gtk.TreeRowReference>();

		private Client client;
		private MetadataRequestor requestor;
		public bool replacenadd;

		public FilterModel (Client c, MetadataResolver resolver, owned string[] props)
		{
			client = c;


			var types = new GLib.Type[2 + props.length];

			types[0] = typeof(int);
			types[1] = typeof(uint);

			for (int i = 2; i < types.length; i++) {
				types[i] = typeof(string);
			}

			set_column_types(types);

			dynamic_columns = (owned) props;

			requestor = resolver.register(on_resolver_complete);
			requestor.set_attributes(dynamic_columns);

			client.medialib_entry_changed.connect((client, res) => {
					on_medialib_info(res);
			});

			replacenadd = false;
		}


		/**
		 * Replaces the content of the filter list model with the
		 * result of a medialib query
		 */
		public bool replace_content (Xmms.Value val)
		{
			Gtk.TreeIter? iter, sibling = null;
			bool is_first = !get_iter_first(out iter);

			clear();

			pos_map.clear();


			bool iscoll=val.is_type(Xmms.ValueType.COLL);
			uint n=0;
			int i=0;
			Xmms.Collection coll = null;
			unowned Xmms.ListIter list_iter = null;
			if(iscoll){
				val.get_coll(out coll);
				n=coll.idlist_get_size();
			}else{
				val.get_list_iter(out list_iter);
				list_iter.first();
 			}

			while (iscoll ? i<n : list_iter.valid()) {
				Gtk.TreeRowReference row;
				Gtk.TreePath path;
				Xmms.Value entry;
				int id = 0;

				if(iscoll){
					if(!coll.idlist_get_index(i,out id)) continue;
				}else{
					if (!(list_iter.entry(out entry) && entry.get_int(out id))) continue;
				}

				if (is_first) {
					insert_after(out iter, null);
					is_first = !is_first;
				} else {
					insert_after(out iter, sibling);
				}

				set(iter, Column.ID, id, Column.STATUS, Status.UNRESOLVED);

				sibling = iter;

				path = get_path(iter);
				row = new Gtk.TreeRowReference(this, path);

				pos_map.set((int) id, row);

				if(replacenadd) client.xmms.playlist_add_id(Xmms.ACTIVE_PLAYLIST, id);

				if(iscoll) i++; else list_iter.next();
			}
			replacenadd = false;

			return true;
		}


		/**
		 * When GTK asks for the value of a column, check if the row
		 * has been resolved or not, otherwise resolve it.
		 */
		public void get_value (Gtk.TreeIter iter, int column, out GLib.Value val)
		{
			GLib.Value tmp1;

			base.get_value(iter, Column.STATUS, out tmp1);
			if (((Status)tmp1.get_int()) == Status.UNRESOLVED) {
				GLib.Value tmp2;

				base.get_value(iter, Column.ID, out tmp2);

				set(iter, Column.STATUS, Status.RESOLVING);

				requestor.resolve((int) tmp2.get_uint());
			}

			base.get_value(iter, column, out val);
		}


		private void on_resolver_complete(Xmms.Value value)
		{
			unowned Xmms.ListIter iter;
			Xmms.Value entry;

			value.get_list_iter(out iter);

			GLib.print("s: %d\n", value.list_get_size());

			while (iter.entry(out entry)) {
				on_medialib_info(entry);
				iter.next();
			}
		}


		private bool on_medialib_info (Xmms.Value val)
		{
			Gtk.TreeRowReference row;
			Gtk.TreePath path;
			Gtk.TreeIter iter;
			int mid;

			val.dict_entry_get_int("id", out mid);

			row = pos_map.get(mid);
			if (row == null || !row.valid()) {
				return false;
			}

			path = row.get_path();

			if (get_iter(out iter, path)) {
				set(iter, Column.STATUS, Status.RESOLVED);

				int pos = 2;
				foreach (unowned string key in dynamic_columns) {
					string formatted = "";
					Transform.normalize_dict (val, key, out formatted);
					set(iter, pos++, formatted);
				}
			}

			select_album_finalize();
			return false;
		}

		public delegate void AddFunc ();
		private Gtk.TreeSelection _select_album_selection = null;
		private AddFunc _select_album_addfunc = null;
		private int _select_album_num = 0;
		public void select_album(Gtk.TreeSelection selection,AddFunc? addfunc=null) {
			Gtk.TreeIter iter;
			_select_album_selection = selection;
			_select_album_addfunc = addfunc;
			_select_album_num = 1;
			get_iter_first(out iter);
			do{
				GLib.Value status;
				base.get_value(iter,Column.STATUS,out status);
				if(((Status)status.get_int())==Status.RESOLVED) continue;
				_select_album_num++;
				get_value(iter,Column.STATUS,out status);
			}while(iter_next(ref iter));
			select_album_finalize();
		}

		private void select_album_finalize() {
			GLib.List<Gtk.TreePath> list;
			unowned Gtk.TreeModel mod;
			int palb;
			if(  _select_album_num == 0) return;
			if(--_select_album_num != 0) return;
			if(_select_album_selection == null) return;
			palb = get_alb_pos();
			list = _select_album_selection.get_selected_rows(out mod);
			foreach (var path in list) {
				Gtk.TreeIter iter;
				string albref;
				get_iter(out iter, path);
				get(iter, palb, out albref);
				get_iter_first(out iter);
				do{
					string albcmp;
					get(iter, palb, out albcmp);
					if(albref==albcmp) _select_album_selection.select_iter(iter);
				}while(iter_next(ref iter));
			}
			if(_select_album_addfunc!=null)
				_select_album_addfunc();
		}

		private int get_alb_pos() {
			int pos = 2;
			int palb = -1;
			foreach (unowned string key in dynamic_columns) {
				if(key == "album"){ palb=pos; break; }
				pos++;
			}
			return palb;
		}
	}
}

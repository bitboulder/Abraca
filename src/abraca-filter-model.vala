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
	public class FilterModel : Gtk.TreeStore, Gtk.TreeModel {
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
		private Gee.HashMap<int,bool> add_map = new Gee.HashMap<int,bool>();

		private Client client;
		private MetadataRequestor requestor;
		public int replacenadd;
		private bool iscoll;

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

			replacenadd = 0;
		}


		/**
		 * Replaces the content of the filter list model with the
		 * result of a medialib query
		 */
		public bool replace_content (Xmms.Value val)
		{
			clear();
			add_map.clear();

			iscoll=val.is_type(Xmms.ValueType.COLL);
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
				Xmms.Value entry;
				int id = 0;

				if(iscoll){
					if(!coll.idlist_get_index(i,out id)) continue;
				}else{
					if (!(list_iter.entry(out entry) && entry.get_int(out id))) continue;
				}

				add_map.set(id,true);
				requestor.resolve((int) id);

				if(replacenadd>0) client.playlist_add_id(id,replacenadd>1);

				if(iscoll) i++; else list_iter.next();
			}
			replacenadd = 0;

			return true;
		}


		private void on_resolver_complete(Xmms.Value value)
		{
			unowned Xmms.ListIter iter;
			Xmms.Value entry;

			value.get_list_iter(out iter);

			while (iter.entry(out entry)) {
				on_medialib_info(entry);
				iter.next();
			}
		}


		private bool on_medialib_info (Xmms.Value val)
		{
			Gtk.TreeIter iter;
			Gtk.TreeIter? ialb=null;
			int mid;

			val.dict_entry_get_int("id", out mid);
			if(!add_map.get(mid)) return false;

			if(!iscoll){
				string alb="", art="";
				Transform.normalize_dict (val, "album", out alb);
				Transform.normalize_dict (val, "artist", out art);
				int palb=get_col_pos("album");
				int part=get_col_pos("artist");
				string ialbtxt="";
				if(get_iter_first(out ialb)){
					set(ialb, Column.ID, -1);
					get(ialb,palb,out ialbtxt);
					while(ialbtxt!=alb && iter_next(ref ialb))
						get(ialb,palb,out ialbtxt);
				}
				if(ialbtxt!=alb){
					append(out ialb,null);
					set(ialb, palb, alb);
					set(ialb, part, art);
				}else{
					string ialbart;
					get(ialb, part, out ialbart);
					if(ialbart!=art) set(ialb,part,"");
				}
				set(ialb,get_col_pos("title"),"[%i]".printf(iter_n_children(ialb)+1));
  			}
  
			append(out iter,ialb);
  
			set(iter, Column.ID, mid);
			set(iter, Column.STATUS, Status.RESOLVED);
  
			int pos = 2;
			foreach (unowned string key in dynamic_columns) {
				string formatted = "";
				Transform.normalize_dict (val, key, out formatted);
				set(iter, pos++, formatted);
  			}
  
			if(iter_n_children(null)==1) FilterView.instance.expand_all(); else FilterView.instance.collapse_all();
  			return false;
  		}
  
		private int get_col_pos(string name) {
  			int pos = 2;
			int p = -1;
  			foreach (unowned string key in dynamic_columns) {
				if(key == name){ p=pos; break; }
  				pos++;
  			}
			return p;
  		}
  	}
}


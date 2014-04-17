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
			ID,
			SID,
			NUM
		}

		/* TODO: This should be a property, not just a member variable */
		public string[] dynamic_columns;

		/* Map medialib id to row */
		private Gee.HashMap<int,int> add_map = new Gee.HashMap<int,int>();

		private Client client;
		private MetadataRequestor requestor;
		public int replacenadd;
		private bool iscoll;

		public FilterModel (Client c, MetadataResolver resolver, owned string[] props)
		{
			client = c;


			var types = new GLib.Type[Column.NUM + props.length];

			types[0] = typeof(int);
			types[1] = typeof(uint);
			types[2] = typeof(int);

			for (int i = Column.NUM; i < types.length; i++) {
				types[i] = typeof(string);
			}

			set_column_types(types);
			set_sort_column_id(Column.SID,Gtk.SortType.ASCENDING);

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
			int sid=0;

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

				add_map.set(id,sid++);
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
			int mid,sid;

			val.dict_entry_get_int("id", out mid);
			if(!add_map.has_key(mid)) return false;
			sid=add_map.get(mid);

			if(!iscoll){
				int palb=get_col_pos("album");
				if(palb>=0){
					int part=get_col_pos("artist");
					int ptit=get_col_pos("title");
					int pdur=get_col_pos("duration");
					string alb="", art="", dur="";
					Transform.normalize_dict (val, "album", out alb);
					if(part>=0) Transform.normalize_dict (val, "artist", out art);
					if(pdur>=0) Transform.normalize_dict (val, "duration", out dur);
					string ialbtxt="";
					if(get_iter_first(out ialb)){
						set(ialb, Column.ID, -1);
						get(ialb,palb,out ialbtxt);
						while(ialbtxt!=alb && iter_next(ref ialb))
							get(ialb,palb,out ialbtxt);
					}
					if(ialbtxt!=alb){
						append(out ialb,null);
						set(ialb, Column.SID, sid);
						set(ialb, palb, alb);
						if(part>=0) set(ialb, part, art);
					}else{
						if(part>=0){
							string ialbart;
							get(ialb, part, out ialbart);
							if(ialbart!=art) set(ialb,part,"");
						}
						int ialbsid;
						get(ialb, Column.SID, out ialbsid);
						if(sid<ialbsid) set(ialb, Column.SID, sid);
					}
					if(ptit>=0) set(ialb,ptit,"[%i]".printf(iter_n_children(ialb)+1));
					if(pdur>=0){
						string ialbdur;
						get(ialb,pdur,out ialbdur);
						set(ialb,pdur,add_dur(ialbdur,dur));
					}
				}
  			}
  
			append(out iter,ialb);
  
			set(iter, Column.ID, mid);
			set(iter, Column.SID, sid);
			set(iter, Column.STATUS, Status.RESOLVED);
  
			int pos = Column.NUM;
			foreach (unowned string key in dynamic_columns) {
				string formatted = "";
				Transform.normalize_dict (val, key, out formatted);
				set(iter, pos++, formatted);
  			}
  
			if(iter_n_children(null)==1) FilterView.instance.expand_all(); else FilterView.instance.collapse_all();
  			return false;
  		}
  
		private int get_col_pos(string name) {
  			int pos = Column.NUM;
			int p = -1;
  			foreach (unowned string key in dynamic_columns) {
				if(key == name){ p=pos; break; }
  				pos++;
  			}
			return p;
  		}

		private string add_dur(string? a, string b){
			if(a==null) return b;
			int a0,a1,b0,b1;
			a.scanf("%d:%d",out a0,out a1);
			b.scanf("%d:%d",out b0,out b1);
			a0+=b0;
			a1+=b1;
			a0+=(int)(a1/60);
			a1%=60;
			return "%d:%d".printf(a0,a1);
		}
  	}
}


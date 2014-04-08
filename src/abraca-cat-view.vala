/**
 * Abraca, an XMMS2 client.
 * Copyright (C) 2008-2010  Abraca Team
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
using Sqlite;

namespace Abraca {

	public class CatView : Gtk.VBox {

		private Client client;
		private Searchable search;
		private Database? db;

		private class CatEntry {

			public class CatMenuItem : Gtk.CheckMenuItem {
				public string key;
				public string lab;

				public CatMenuItem(string _key,string _lab){
					key=_key;
					lab=_lab;
					update_lab(-1);
				}
				
				public void update_lab(int num){
					if(num<0) set_label(lab);
					else set_label("%s (%i)".printf(lab,num));
				}
			}

			public string name;
			public string sql;
			public GLib.List<CatMenuItem> mis;
			public Gtk.Button btn;

			public CatEntry(string n,string v){
				name=n;
				sql="";
				string[] val=v.split(":");
				for(int i=0;i<val.length;i+=2) mis.append(new CatMenuItem(val[i],val[i+1]));
				var menu=new Gtk.Menu();
				foreach(var mi in mis){
					mi.set_draw_as_radio(true);
					menu.append(mi);
				}
				menu.set_title(name);
				menu.show_all();
				btn=new Gtk.Button.with_label(name + " (egal)");
				btn.clicked.connect((btn) => { menu.popup(null,null,null,0,Gtk.get_current_event_time()); });
			}
		}

		private GLib.List<CatEntry> ce;

		public CatView (Client _client, Searchable _search)
		{
			if(Database.open_v2("/home/frank/.config/xmms2/medialib.db",out db,Sqlite.OPEN_READONLY)!=Sqlite.OK) db=null;
			ce = new GLib.List<CatEntry> ();
			ce.append(new CatEntry("Angehört","f:sehr oft:e:oft:d:mittel:c:selten:b:sehr selten:a:nie"));
			ce.append(new CatEntry("Sprache","d:deutsch:e:englisch:o:andere:i:instrumental"));
			ce.append(new CatEntry("christlich","y:ja:n:nein"));
			ce.append(new CatEntry("Weihnachten","y:ja:n:nein"));

			client = _client;
			search = _search;

			foreach(var cat in ce){
				foreach(var mi in cat.mis){ mi.toggled.connect(on_toggled); }
				pack_start(cat.btn,false,false,0);
			}
			update_num();
		}

		private void on_toggled (Gtk.CheckMenuItem s)
		{
			string pat="cat:";
			string pre="";
			foreach(var cat in ce){
				string selstr="";
				string patadd="";
				bool all=true;
				bool none=true;
				cat.sql="";
				foreach(var mi in cat.mis){
					if(mi.get_active()){
						selstr+=(none?"":",")+mi.lab;
						patadd+=(none?"":" OR ")+mi.key;
						cat.sql+=(none?"":" OR ")+"value like '"+pre+mi.key+"%'";
						none=false;
					}else all=false;
				}
				if(all || none){ selstr="egal"; patadd="?"; cat.sql=""; }
				cat.btn.set_label(cat.name+" ("+selstr+")");
				string patnew="";
				foreach(var p in pat.split(" OR ")){
					foreach(var pa in patadd.split(" OR ")){
						patnew+=(patnew==""?"":" OR ")+p+pa;
					}
				}
				pat=patnew;
				pre+="_";
			}
			search.search(pat,false);
			update_num();
		}

		private void update_num()
		{
			if(db==null) return;
			string pre="";
			foreach(var cat in ce){
				string sql="";
				foreach(var cat2 in ce) if(cat2!=cat && cat2.sql!="") sql+=(sql==""?"":" AND ")+"( "+cat2.sql+" )";
				foreach(var mi in cat.mis){
					Statement stmt;
					string sqlm="value like '"+pre+mi.key+"%'";
					if(sql!="") sqlm+=" AND "+sql;
					db.prepare("SELECT COUNT(value) FROM Media WHERE key='cat' AND "+sqlm,-1,out stmt);
					int num=-1;
					while(stmt.step()==Sqlite.ROW) num=stmt.column_int(0);
					mi.update_lab(num);
				}
				pre+="_";
			}
		}
	}
}

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

	public class ImageMenuItem : Gtk.MenuItem {
		public ImageMenuItem.with_icon_label(string _icon_name,string _label){
			var box=new Gtk.Box(Gtk.Orientation.HORIZONTAL,0);
			if(_icon_name!=""){
				var img = new Gtk.Image.from_icon_name(_icon_name,Gtk.IconSize.MENU);
				box.pack_start(img,false,false,0);
			}
			var lab=new Gtk.Label(_label);
			box.pack_start(lab,true,true,0);
			child=box;
		}
	}
}


/**
 * Abraca, an XMMS2 client.
 * Copyright (C) 2009-2013 Abraca Team
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

namespace Abraca {

	public static void create_icons() throws GLib.Error {

		Gtk.IconTheme.add_builtin_icon("abraca-icon",      32,new Gdk.Pixbuf.from_resource("/org/xmms2/Abraca/abraca-32.png"));
		Gtk.IconTheme.add_builtin_icon("abraca-equalizer", 24,new Gdk.Pixbuf.from_resource("/org/xmms2/Abraca/abraca-equalizer.png"));
		Gtk.IconTheme.add_builtin_icon("abraca-collection",24,new Gdk.Pixbuf.from_resource("/org/xmms2/Abraca/abraca-collection-24.png"));
		Gtk.IconTheme.add_builtin_icon("abraca-collection",16,new Gdk.Pixbuf.from_resource("/org/xmms2/Abraca/abraca-collection-16.png"));
		Gtk.IconTheme.add_builtin_icon("abraca-playlist",  24,new Gdk.Pixbuf.from_resource("/org/xmms2/Abraca/abraca-playlist-24.png"));
		Gtk.IconTheme.add_builtin_icon("abraca-playlist",  16,new Gdk.Pixbuf.from_resource("/org/xmms2/Abraca/abraca-playlist-16.png"));
		Gtk.IconTheme.add_builtin_icon("abraca-addall",    24,new Gdk.Pixbuf.from_resource("/org/xmms2/Abraca/abraca-addall-24.png"));
		Gtk.IconTheme.add_builtin_icon("abraca-addall",    16,new Gdk.Pixbuf.from_resource("/org/xmms2/Abraca/abraca-addall-16.png"));
		Gtk.IconTheme.add_builtin_icon("abraca-rated",     16,new Gdk.Pixbuf.from_resource("/org/xmms2/Abraca/abraca-rating-rated.png"));
		Gtk.IconTheme.add_builtin_icon("abraca-unrated",   16,new Gdk.Pixbuf.from_resource("/org/xmms2/Abraca/abraca-rating-unrated.png"));
		Gtk.IconTheme.add_builtin_icon("abraca-favorite",  16,new Gdk.Pixbuf.from_resource("/org/xmms2/Abraca/abraca-favorite.png"));

	}
}

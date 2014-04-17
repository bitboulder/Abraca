public class Abraca.FilterSearchBox : Gtk.ComboBox, Searchable {
	private Gee.Queue<string> _pending_queries = new Gee.LinkedList<string>();
	private string _unsaved_query;
	private string _current_query;
	private uint _timer = 0;

	/* TODO: this is a hack, remove me */
	private FilterView treeview;

	public FilterSearchBox (Client client, Config config, FilterView tv)
	{
		Object (has_entry: true, entry_text_column: 0);

		treeview = tv;

		model = new Gtk.ListStore.newv({ typeof(string) });

		var entry = get_child() as Gtk.Entry;
		entry.primary_icon_name = "edit-find";
		entry.secondary_icon_name = "edit-clear";
		entry.secondary_icon_activatable = true;

		entry.changed.connect(on_filter_entry_changed);
		entry.icon_release.connect(on_filter_entry_clear);
		entry.focus_out_event.connect(on_filter_entry_focus_out_event);

		var completion = new Gtk.EntryCompletion();
		completion.set_text_column(0);
		completion.model = model;

		entry.set_completion(completion);
	}


	public void set_configuration (GLib.KeyFile file)
		throws GLib.KeyFileError
	{
		if (!file.has_group("filter") || !file.has_key("filter", "patterns"))
			return;

		var store = model as Gtk.ListStore;
		Gtk.TreeIter iter;

		var list = file.get_string_list("filter", "patterns");

		for (int i = 0; i < list.length; i++)
			store.insert_with_values(out iter, i, 0, list[i]);
	}


	public void get_configuration (GLib.KeyFile file)
	{
		Gtk.TreeIter iter;
		string current;
		int i = 0;

		var store = model as Gtk.ListStore;
		var list = new string[25];

		if (store.iter_children(out iter, null)) {
			do {
				store.get(iter, 0, out current);
				list[i++] = current;
			} while (store.iter_next(ref iter) && i < 25);
		}

		file.set_string_list("filter", "patterns", list);
	}


	private void _filter_save (string pattern)
	{
		Gtk.ListStore store = (Gtk.ListStore) model;
		Gtk.TreeIter iter;
		string current;

		if (store.iter_children(out iter, null)) {
			do {
				store.get(iter, 0, out current);
				if (current == pattern) {
					store.remove(iter);
					break;
				}
			} while (store.iter_next(ref iter));
		}

		store.insert_with_values(out iter, 0, 0, pattern);
	}


	private void on_filter_entry_clear (Gtk.Entry entry, Gtk.EntryIconPosition pos, Gdk.Event ev)
	{
		if (pos == Gtk.EntryIconPosition.PRIMARY)
			return;

		entry.text = "";
	}


	private void on_filter_entry_changed (Gtk.Editable widget)
	{
		Gdk.RGBA? color = null;
		Xmms.Collection coll;

		var entry = widget as Gtk.Entry;
		var text = entry.get_text();
		if(text.length>0 && !text.contains(":")){
			for(int i=0;i<text.length;i++) if(text.substring(i,1)==" "){
				text = text.substring(0,i) + "\\" + text.substring(i);
				i++;
			}	
			text = "*" + text + "*";
		}

		if (text.length > 0) {
			if (Xmms.Collection.parse(text, out coll)) {
				_current_query = text;

				// Throttle collection querying
				if (_timer == 0) {
					_timer = GLib.Timeout.add(450, on_collection_query_timeout);
				}
				if(text.length>3  && text.substring(0,3)=="in:"){
					color=Gdk.RGBA();
					color.parse("#ffff66");
				}
			} else {
				color = Gdk.RGBA();
				color.parse("#ff6666");
			}
		}

		entry.override_background_color(Gtk.StateFlags.NORMAL, color);
	}


	private bool on_collection_query_timeout()
	{
		return on_collection_query_timeout_ex(true);
	}

	private bool on_collection_query_timeout_ex(bool filter_native_sort)
	{
		Xmms.Collection coll;

		if (_current_query == null) {
			_timer = 0;
			return false;
		}

		if(_current_query.length>19){
			if(_current_query.substring(0,19)=="in:Collections/alb_") treeview.set_sort_def("album");
			else if(_current_query.substring(0,19)=="in:Collections/art_") treeview.set_sort_def("artist");
			else treeview.set_sort_def(null);
		}

		if (!Xmms.Collection.parse(_current_query, out coll)) {
			_current_query = null;
			_timer = 0;
			return false;
		}

		_pending_queries.offer(_current_query);

		string native_sort_pl="";
		if(filter_native_sort && _current_query.length>=13 &&
				_current_query.substring(0,13)=="in:Playlists/")
			native_sort_pl = _current_query.substring(13);
		treeview.query_collection_ex(coll, native_sort_pl, (val) => {
			var s = _pending_queries.poll();
			if (s != null && !val.is_type(Xmms.ValueType.COLL) && val.list_get_size() > 0) {
				if (get_child().has_focus) {
					_unsaved_query = s;
				} else if (_pending_queries.is_empty) {
					_filter_save(s);
				}
			}
			return true;
		});

		_current_query = null;

		return true;
	}


	private bool on_filter_entry_focus_out_event (Gtk.Widget w, Gdk.EventFocus e)
	{
		if (_unsaved_query != null && _unsaved_query == (w as Gtk.Entry).text) {
			_filter_save(_unsaved_query);
		}

		_unsaved_query = null;

		return false;
	}


	public void search(string text,int replacenadd = 0)
	{
		var entry = get_child() as Gtk.Entry;
		((FilterModel)treeview.model).replacenadd = replacenadd;
		entry.text = "";
		entry.text = text;
		on_collection_query_timeout();
	}

}

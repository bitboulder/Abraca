public class Abraca.RptButton : Gtk.Button{
	private Client _client;
	private int state=0;
	public RptButton(Client client){
		_client=client;
		relief = Gtk.ReliefStyle.NONE;
		has_tooltip=true;
		query_tooltip.connect((w,x,y,mode,tooltip)=>{tooltip.set_text(_("Repeat")); return true; });
		set_lab();
		clicked.connect(on_click);
		_client.connection_state_changed.connect(on_connect);
	}
	private void set_lab(){
		switch(state){
		case 0: set_label("R-NON"); break;
		case 1: set_label("R-ALL"); break;
		case 2: set_label("R-ONE"); break;
		}
	}
	private void on_click(){
		state=(state+1)%3;
		set_lab();
		_client.xmms.config_set_value("playlist.repeat_all", state==1 ? "1" : "0");
		_client.xmms.config_set_value("playlist.repeat_one", state==2 ? "1" : "0");
	}
	private void on_connect(Client.ConnectionState cstate){
		if(cstate!=Client.ConnectionState.Connected) return;
		_client.xmms.config_get_value("playlist.repeat_all").notifier_set(on_rpt_all);
		_client.xmms.config_get_value("playlist.repeat_one").notifier_set(on_rpt_one);
	}
	private bool on_rpt_all(Xmms.Value val){
		string v;
		if(val.get_string(out v)){
			if(v=="1") state=1;
			else if(state==1) state=0;
			set_lab();
		}
		return true;
	}
	private bool on_rpt_one(Xmms.Value val){
		string v;
		if(val.get_string(out v)){
			if(v=="1") state=2;
			else if(state==2) state=0;
			set_lab();
		}
		return true;
	}
}


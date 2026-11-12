extends SceneTree
var shell
func _initialize():call_deferred("run")
func frames(n):
	for i in n:await physics_frame
func mounted():
	while shell.mounting or shell.mount_queued or shell.arena==null:await process_frame
func tap(name):
	for down in [true,false]:
		var e=InputEventAction.new();e.action=name;e.pressed=down;Input.parse_input_event(e);await process_frame
func run():
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);shell.tutorial_enabled=false
	var c=shell.coordinator;c.saver=SaveService.new("user://dev508-immediate")
	if "--verify" in OS.get_cmdline_user_args():
		assert(shell.load_selected(false).ok);await mounted()
		assert(c.state.items[c.state.player.equipment.weapon_1]==c.state.session.exit_probe)
		print("DEV508_POST_EXPLOSION_DISK_RECORD_PASS")
		shell.request_exit();shell.request_exit();return
	if "--read" not in OS.get_cmdline_user_args():
		assert(c.create_world(441).ok);await mounted()
		assert(c.state.base.residents.is_empty())
		var id=c.state.player.equipment.weapon_1
		assert(c.state.items[id].plugins.is_empty())
		c.state.base.energy_store.energy=900;c.state.base["technology"]={"storage":true}
		c.services.inventory.spawn(c.state,"scrap","warehouse",80);c.services.inventory.spawn(c.state,"boss_core","warehouse",1)
		var plugin=c.services.inventory.spawn(c.state,"tactical_launcher","warehouse",1).id
		var station=""
		for b in c.state.base.buildings.values():
			if b.type=="workstation":station=b.id
		assert(c.services.workstation.modify(c.state,station,id,"install",plugin))
		assert(c.services.workstation.modify(c.state,station,id,"upgrade","rifle_advanced"))
		var other=c.services.inventory.spawn(c.state,"rifle_advanced","warehouse",1).id
		shell.arena.management.root_panel.hide()
		await tap("charge");await frames(180);await tap("charge")
		assert(c.state.items[id].energy>=30)
		assert(c.depart("suburbs","south").ok);shell.queue_mount();await mounted()
		c.state.session.qa603={"gun":id,"plugin":plugin,"other":other,"record":c.state.items[id].duplicate(true)}
		assert(c.shutdown().ok)
		print("QA603_WRITE_REAL_UPGRADE_CHARGE_PASS")
	else:
		assert(shell.load_selected(false).ok);await mounted()
		var probe=c.state.session.qa603
		var gun=c.state.items[probe.gun]
		assert(gun==probe.record and gun.plugins.tactical==probe.plugin)
		assert(c.state.items[probe.other].plugins.is_empty())
		var a=shell.arena;var p=a.player;var enemy=a.targets[0]
		for target in a.targets:target.set_physics_process(false)
		p.position=Vector2(400,400);enemy.position=p.position+Vector2(70,0)
		var point=a.get_canvas_transform()*enemy.global_position
		var motion=InputEventMouseMotion.new();motion.position=point;motion.global_position=point;Input.parse_input_event(motion)
		await frames(3)
		var hp=enemy.record().vitals.hp;var power=gun.energy
		Input.action_press("fire");await frames(16);Input.action_release("fire")
		assert(enemy.record().vitals.hp<hp and gun.energy<power)
		print("QA603_RESTORED_REAL_PROJECTILE_DAMAGE_PASS")
		await frames(25);await tap("weapon_next")
		enemy.position=p.position+Vector2(40,0)
		hp=enemy.record().vitals.hp
		Input.action_press("fire");await frames(3);Input.action_release("fire")
		assert(enemy.record().vitals.hp<hp)
		print("QA603_RESTORED_REAL_MELEE_PASS")
		await frames(30);await tap("weapon_previous");await tap("tactical")
		enemy=a.targets[1];enemy.position=p.position+Vector2(160,0)
		point=a.get_canvas_transform()*enemy.global_position
		motion.position=point;motion.global_position=point;Input.parse_input_event(motion)
		await frames(3);hp=enemy.record().vitals.hp
		power=gun.energy
		Input.action_press("fire");await frames(2);Input.action_release("fire")
		assert(is_equal_approx(power-gun.energy,15))
		while p.tactical.flight>0:await physics_frame
		assert(enemy.record().vitals.hp<hp)
		print("QA603_RESTORED_LAUNCHER_ENERGY_DAMAGE_PASS")
	c.state.session.exit_probe=c.state.items[c.state.player.equipment.weapon_1].duplicate(true)
	shell.request_exit();shell.request_exit()



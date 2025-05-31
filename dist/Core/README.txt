Static vs Dynamic Effects

For performance reasons there are static and dynamic effects. Static effects were designed with performance in mind. They require a plugin quest script, but offer even more advanced options than dynamic effects. Since Static effects are present on every character, so they should be used for very common effects.

Dynamic effects are slow when changed often, but otherwise offer similair good performance and are way easier to implement.

 

Adding Dynamic Effects:

int handle = ModEvent.Create("slaSetArousalEffect")
ModEvent.PushForm(handle, who) ; The affected actor
ModEvent.PushString(handle, "DDTeasing") ; Internal identifycation
ModEvent.PushFloat(handle, 50.0) ; initial value
ModEvent.PushInt(handle, 1) ; timed function to use (see below)
ModEvent.PushFloat(handle, 1.0 / 24.0) ; parameter $param of timed function
ModEvent.PushFloat(handle, 0.0) ; stop function at
ModEvent.Send(handle)

 

Timed Function Id:

0 - none
1 - reduce by 50% after $param ingame days
2 - change effect value by $param per day
3 - effect value is equal to (sin(days * $param) + 1.0) * limit
4 - effect value is 0 if time < $param otherwise limit

 

Adding Static Effects:

Refer to an existing static effect plugin like Sexlab (sla_sexlabplugin.psc) or Devious Devices (sla_ddplugin.psc). Some documentation regarding the functions to implement for your plugin can be found in sla_pluginbase.psc).
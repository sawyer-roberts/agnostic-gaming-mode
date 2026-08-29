#!/usr/bin/env python3
import evdev
from evdev import UInput, ecodes as e
import asyncio

# Create a virtual controller in Steam
cap = { e.EV_KEY: [e.BTN_MODE, e.BTN_A, e.BTN_B] }
ui = UInput(cap, name="Keyboard + Mouse")

async def listen(dev):
	try:
		async for event in dev.async_read_loop():
			if event.type == e.EV_KEY:
				
				# Press Steam button when Shift + Meta is pressed
				# Meta -> F17 by keyd while Shift is pressed
				if event.code == e.KEY_F17:
					if event.value in [0, 1]: 
						ui.write(e.EV_KEY, e.BTN_MODE, event.value)
						ui.syn()
				
				# Press A button when Shift + Alt is pressed
				# Alt -> F16 by keyd while Shift is pressed
				elif event.code == e.KEY_F16:
					if event.value in [0, 1]:
						ui.write(e.EV_KEY, e.BTN_A, event.value)
						ui.syn()
						
				# Press B button when Shift + Escape is pressed
				# Escape -> F15 by keyd while Shift is pressed
				elif event.code == e.KEY_F15:
					if event.value in [0, 1]:
						ui.write(e.EV_KEY, e.BTN_B, event.value)
						ui.syn()
						
	except Exception:
		pass

async def main():
	active_tasks = {}
	while True:
		current_paths = set(evdev.list_devices())
		
		# Start tasks for new or completed devices
		for path in current_paths:
			if path not in active_tasks or active_tasks[path].done():
				try:
					dev = evdev.InputDevice(path)
					# Look for keyboards by checking if a SPACE key is present
					if e.EV_KEY in dev.capabilities() and e.KEY_SPACE in dev.capabilities()[e.EV_KEY]:
						active_tasks[path] = asyncio.create_task(listen(dev))
				except Exception:
					pass
		
		# Clean up tasks for disconnected devices
		for path in list(active_tasks.keys()):
			if path not in current_paths:
				task = active_tasks.pop(path)
				if not task.done():
					task.cancel()
					
		await asyncio.sleep(1)

if __name__ == '__main__':
	asyncio.run(main())

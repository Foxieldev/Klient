import dearpygui.dearpygui as dpg
import json, os, time, threading, asyncio

try:
    import websockets # type: ignore
except ImportError:
    import subprocess, sys
    subprocess.check_call([sys.executable, "-m", "pip", "install", "websockets", "-q"])
    import websockets # type: ignore

# If you watched the video, my bad on my part for not telling you how to do this. I'll tell you here.
# Set the directory to your executor path, and to the klient path if you have ran the script yet (do that before running the python code)
# It's recommended that you use a good executor at least (for good paid executors, go to https://weao.xyz, I recommend Volt, Seliware, Velocity? and Potassium.)
workspace = r"C:\Users\YOURPCUSER\AppData\Local\YOUREXECUTOR\workspace\klient"

Modules = {
    "Blatant": [
        {
            "tag": "walkspeed",
            "name": "Speed",
            "settings": {
                "enabled": False,
                "value": (0,16,100)
            }
        }
    ],
    "Utility": [
        {
            "tag": "fov",
            "name": "CustomFOV",
            "settings": {
                "enabled": False,
                "value": (30,60,120)
            }
        }
    ]
}

def build_defaults():
    data = {}
    for _, mods in Modules.items():
        for mod in mods:
            tag = mod["tag"]
            for key, val in mod["settings"].items():
                if key == "enabled":
                    data[f"{tag}_enabled"] = val
                elif isinstance(val, tuple):
                    data[f"{tag}_{key}"] = val[1]
    return data

def load():
    defaults = build_defaults()
    for k in defaults:
        path = os.path.join(workspace, f"{k}.json")
        if os.path.exists(path):
            try:
                with open(path, "r") as f:
                    defaults[k] = json.load(f)
            except:
                pass
    return defaults

def save_key(k, v):
    os.makedirs(workspace, exist_ok=True)
    with open(os.path.join(workspace, f"{k}.json"), "w") as f:
        json.dump(v, f)

cfg = load()

ws_clients = set()
ws_lock = threading.Lock()
ws_loop = None

def push(key, value):
    msg = json.dumps({"k": key, "v": value})
    async def _send():
        with ws_lock:
            clients = list(ws_clients)
        dead = set()
        for c in clients:
            try:
                await c.send(msg)
            except:
                dead.add(c)
        if dead:
            with ws_lock:
                ws_clients.difference_update(dead)
    if ws_loop and ws_loop.is_running():
        asyncio.run_coroutine_threadsafe(_send(), ws_loop)

def setv(sender, app_data, user_data):
    cfg[user_data] = app_data
    save_key(user_data, app_data)
    push(user_data, app_data)

async def ws_handler(websocket):
    with ws_lock:
        ws_clients.add(websocket)

    for k, v in cfg.items():
        try:
            await websocket.send(json.dumps({"k": k, "v": v}))
        except:
            break

    try:
        async for _ in websocket:
            pass
    except:
        pass
    finally:
        with ws_lock:
            ws_clients.discard(websocket)

async def ws_main():
    global ws_loop
    ws_loop = asyncio.get_event_loop()
    async with websockets.serve(ws_handler, "localhost", 7823, ping_interval=None):
        await asyncio.Future()

threading.Thread(target=lambda: asyncio.run(ws_main()), daemon=True).start()

dpg.create_context()

with dpg.theme() as theme:
    with dpg.theme_component(dpg.mvAll):
        dpg.add_theme_color(dpg.mvThemeCol_WindowBg,(20,20,20,255))
        dpg.add_theme_color(dpg.mvThemeCol_FrameBg,(35,35,35,255))
        dpg.add_theme_color(dpg.mvThemeCol_FrameBgHovered,(45,45,45,255))
        dpg.add_theme_color(dpg.mvThemeCol_FrameBgActive,(55,55,55,255))
        dpg.add_theme_color(dpg.mvThemeCol_Button,(40,40,40,255))
        dpg.add_theme_color(dpg.mvThemeCol_ButtonHovered,(60,60,60,255))
        dpg.add_theme_color(dpg.mvThemeCol_ButtonActive,(75,75,75,255))
        dpg.add_theme_color(dpg.mvThemeCol_Header,(40,40,40,255))
        dpg.add_theme_color(dpg.mvThemeCol_HeaderHovered,(60,60,60,255))
        dpg.add_theme_color(dpg.mvThemeCol_HeaderActive,(75,75,75,255))
        dpg.add_theme_color(dpg.mvThemeCol_Tab,(30,30,30,255))
        dpg.add_theme_color(dpg.mvThemeCol_TabHovered,(55,55,55,255))
        dpg.add_theme_color(dpg.mvThemeCol_TabActive,(65,65,65,255))
        dpg.add_theme_color(dpg.mvThemeCol_CheckMark,(255,255,255,255))
        dpg.add_theme_color(dpg.mvThemeCol_SliderGrab,(200,200,200,255))
        dpg.add_theme_color(dpg.mvThemeCol_SliderGrabActive,(255,255,255,255))
        dpg.add_theme_color(dpg.mvThemeCol_Text,(255,255,255,255))

with dpg.window(tag="main", width=470, height=560, no_title_bar=True):
    with dpg.tab_bar():
        for tab_name, mods in Modules.items():
            with dpg.tab(label=tab_name):
                for mod in mods:
                    tag = mod["tag"]
                    name = mod["name"]
                    with dpg.collapsing_header(label=name):
                        for key, val in mod["settings"].items():
                            json_key = f"{tag}_{key}"
                            if key == "enabled":
                                dpg.add_checkbox(
                                    label="Enabled",
                                    default_value=cfg[json_key],
                                    callback=setv,
                                    user_data=json_key
                                )
                            elif isinstance(val, tuple):
                                minv, defaultv, maxv = val
                                dpg.add_slider_int(
                                    label=key.capitalize(),
                                    default_value=cfg[json_key],
                                    min_value=minv,
                                    max_value=maxv,
                                    callback=setv,
                                    user_data=json_key
                                )

dpg.bind_theme(theme)
dpg.create_viewport(title="Klient", width=470, height=560)
dpg.setup_dearpygui()
dpg.show_viewport()
dpg.set_primary_window("main", True)
dpg.start_dearpygui()
dpg.destroy_context()

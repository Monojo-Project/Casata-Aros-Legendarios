#!/bin/lua

----------- Variables globales ----------
local home = os.getenv("HOME") or "~"
local defaultRoot = home .. "/.infernal"
local infernalRoot = defaultRoot

----------- Instalación Automática (Primera Ejecución) -----
local function instalarEnPrimeraEjecucion()
    local sourceDir = "/usr/local/casata/apps/infernal/infernal"
    local lockFile = infernalRoot .. "/.installed"
    
    -- Verificar si ya se ha instalado
    local f = io.open(lockFile, "r")
    if f then
        f:close()
        return  -- Ya instalado
    end

    -- Verificar que la fuente existe
    local checkSource = io.open(sourceDir, "r")
    if not checkSource then return end -- No es la ruta, no instalamos
    checkSource:close()
    
    print("\27[1;33m⚡ Primera ejecución: Instalando archivos...\27[0m")
    os.execute("mkdir -p '" .. infernalRoot:gsub("'", "'\\''") .. "'")
    
    -- Copiar todo EXCEPTO infernal.lua usando find
    local copyCmd = "find '" .. sourceDir .. "' -maxdepth 1 -mindepth 1 ! -name 'infernal.lua' -exec cp -r {} '" .. infernalRoot .. "/' \\;"
    os.execute(copyCmd)
    
    -- Crear lock
    local lockF = io.open(lockFile, "w")
    if lockF then
        lockF:write("installed\n")
        lockF:close()
    end
    print("\27[1;32m✓ Instalación completada en " .. infernalRoot .. "\27[0m")
end

-- Ejecutar instalación
instalarEnPrimeraEjecucion()

----------- Funciones del Sistema ----------
local function capturarComando(comando)
    local pipe = io.popen(comando)
    if not pipe then return "" end
    local resultado = pipe:read("*all")
    pipe:close()
    return resultado:gsub("%s+$", "")
end

local function ejecutarComandoPersonalizado(cmd, dirActual)
    local base = cmd:match("^(%S+)")
    if not base then return end
    local safeDir = dirActual:gsub("'", "'\\''")
    local args = cmd:sub(#base + 1)
    local ruta_ejecutable = nil

    if not base:find("/") then
        local app_path = infernalRoot .. "/apps/" .. base
        local safe_app = app_path:gsub("'", "'\\''")
        local test_result = os.execute("test -x '" .. safe_app .. "'")
        if test_result == 0 or test_result == true then
            ruta_ejecutable = app_path
        else
            local localbin_path = home .. "/.local/bin/" .. base
            local safe_local = localbin_path:gsub("'", "'\\''")
            test_result = os.execute("test -x '" .. safe_local .. "'")
            if test_result == 0 or test_result == true then
                ruta_ejecutable = localbin_path
            end
        end
    end

    local comando_final
    if ruta_ejecutable then
        local safe_exe = ruta_ejecutable:gsub("'", "'\\''")
        comando_final = "'" .. safe_exe .. "'" .. args
    else
        comando_final = cmd
    end

    os.execute("cd '" .. safeDir .. "' && " .. comando_final)
end

local function directorioExiste(ruta)
    if not ruta or ruta == "" then return false end
    local test = os.execute("test -d '" .. ruta:gsub("'", "'\\''") .. "'")
    return (test == 0 or test == true)
end

local function getDirectorioInicial()
    return capturarComando("pwd")
end

-- Función que sube hasta encontrar un directorio existente
local function subirHastaExistente(ruta)
    if not ruta or ruta == "" then return home end
    local current = ruta
    while true do
        if directorioExiste(current) then
            return current
        end
        -- Si ya estamos en la raíz y no existe, devolver home
        if current == "/" or current == "" then
            return home
        end
        -- Recortar el último componente
        local last_slash = current:match("^(.*)/[^/]*$")
        if not last_slash or last_slash == "" then
            return home
        end
        current = last_slash
    end
end

----------- Tabla de colores ----------
local colores = {
    azul  = "\27[34m", verde = "\27[32m", rojo  = "\27[31m",
    negro   = "\27[30m", amarillo= "\27[33m", magenta = "\27[35m",
    cian    = "\27[36m", blanco  = "\27[37m",
    azul_bold  = "\27[1;34m", verde_bold = "\27[1;32m",
    rojo_bold  = "\27[1;31m", negro_bold   = "\27[1;30m",
    amarillo_bold= "\27[1;33m", magenta_bold = "\27[1;35m",
    cian_bold    = "\27[1;36m", blanco_bold  = "\27[1;37m",
    blue  = "\27[34m", green = "\27[32m", red   = "\27[31m",
    black = "\27[30m", yellow= "\27[33m", orange= "\27[33m",
    magenta = "\27[35m", cyan    = "\27[36m", white   = "\27[37m",
    blue_bold  = "\27[1;34m", green_bold = "\27[1;32m",
    red_bold   = "\27[1;31m", black_bold   = "\27[1;30m",
    yellow_bold= "\27[1;33m", magenta_bold = "\27[1;35m",
    cyan_bold    = "\27[1;36m", white_bold  = "\27[1;37m",
    orange_bold = "\27[1;33m",
    bold  = "\27[1m", reset = "\27[0m"
}

----------- Lectura y creación de configuración ----------
local function cargarConfiguracion(ruta)
    local file = io.open(ruta, "r")
    if not file then return nil end
    local config = {}
    for raw_line in file:lines() do
        local line = raw_line:gsub("%s+$", ""):gsub("^%s+", "")
        if line ~= "" and not line:match("^%[") and not line:match("^#") then
            local key, value = line:match("^([^=]+)=(.*)$")
            if key and value then
                config[key:gsub("%s+$", ""):gsub("^%s+", "")] = value:gsub("%s+$", ""):gsub("^%s+", "")
            end
        end
    end
    file:close()
    return config
end

local function crearConfiguracionPorDefecto(ruta)
    local contenido = [[[Infernal configuration]
Folders=blue
Symlinks=orange
Files=white
Executables=green
ShowFetch=true
Logo=Logo2
UserColor=red
HostnameColor=red
AtsingColor=red
PwdColor=blue
Root=~/.infernal
]]
    local file = io.open(ruta, "w")
    if file then
        file:write(contenido)
        file:close()
        return true
    end
    return false
end

----------- Determinar root y cargar configuración ----------
local function obtenerConfig(root)
    local configPath = root .. "/Infernal.conf"
    local config = cargarConfiguracion(configPath)
    if not config then
        crearConfiguracionPorDefecto(configPath)
        config = cargarConfiguracion(configPath)
    end
    return config
end

local config = obtenerConfig(defaultRoot)

if config and config.Root then
    local newRoot = config.Root:gsub("^~", home)
    if newRoot ~= defaultRoot then
        infernalRoot = newRoot
        config = obtenerConfig(infernalRoot)
        config.Root = infernalRoot:gsub(home, "~")
    end
end

os.execute("mkdir -p '" .. infernalRoot:gsub("'", "'\\''") .. "/apps'")

----------- Obtener colores para ls y prompt ----------
local colorMapNumber = {
    blue = "34", green = "32", red = "31", yellow = "33", orange = "33",
    magenta = "35", cyan = "36", white = "37", black = "30"
}

local diColor = colorMapNumber[config.Folders and config.Folders:lower() or "blue"] or "34"
local exColor = colorMapNumber[config.Executables and config.Executables:lower() or "green"] or "32"
local lnColor = colorMapNumber[config.Symlinks and config.Symlinks:lower() or "orange"] or "33"
local fiColor = colorMapNumber[config.Files and config.Files:lower() or "white"] or "37"

local lsColors = "di=1;" .. diColor .. ":ex=1;" .. exColor .. ":ln=1;" .. lnColor .. ":fi=1;" .. fiColor

local userColorName = (config.UserColor and config.UserColor:lower()) or "red"
local hostColorName = (config.HostnameColor and config.HostnameColor:lower()) or "red"
local atColorName = (config.AtsingColor and config.AtsingColor:lower()) or "red"
local pwdColorName = (config.PwdColor and config.PwdColor:lower()) or "blue"

local promptUserColor = colores.bold .. (colores[userColorName] or colores.red)
local promptHostColor = colores.bold .. (colores[hostColorName] or colores.red)
local promptAtColor = colores[atColorName] or colores.red
local promptPwdColor = colores.bold .. (colores[pwdColorName] or colores.blue)

----------- Funciones del Shell ----------
local function leerComando(user, hostname, dirActual)
    local historyFile = infernalRoot .. "/History"
    local tempCmdFile = "/tmp/.infernal_cmd"
    local runnerFile = "/tmp/.infernal_runner.sh"

    if not directorioExiste(dirActual) then
        dirActual = subirHastaExistente(dirActual)
    end

    local safeDir = dirActual:gsub("'", "'\\''")

    local display_dir = dirActual
    if home ~= "" and dirActual:find(home, 1, true) == 1 then
        display_dir = dirActual:gsub("^" .. home, "~")
    end
    local safeDisplayDir = display_dir:gsub("'", "'\\''")

    local pUser = "\1" .. promptUserColor .. "\2" .. user .. "\1" .. colores.reset .. "\2"
    local pArroba = "\1" .. promptAtColor .. "\2@\1" .. colores.reset .. "\2"
    local pHost = "\1" .. promptHostColor .. "\2" .. hostname .. "\1" .. colores.reset .. "\2"
    local pDir = "\1" .. promptPwdColor .. "\2" .. safeDisplayDir .. "\1" .. colores.reset .. "\2"

    local promptFinal = pUser .. pArroba .. pHost .. ":" .. pDir .. "$ "

    os.remove(tempCmdFile)

    local bash_script = string.format([[
#!/bin/bash
cd '%s' 2>/dev/null || cd "$HOME" 2>/dev/null
HISTFILE="%s"
touch "$HISTFILE" 2>/dev/null
history -r "$HISTFILE" 2>/dev/null

trap 'echo "" > "%s"; exit 130' SIGINT

read -e -p "%s" cmd </dev/tty

if [ -n "$cmd" ]; then
    history -s "$cmd"
    history -w "$HISTFILE"
fi
echo "$cmd" > "%s"
    ]], safeDir, historyFile, tempCmdFile, promptFinal, tempCmdFile)

    local rf = io.open(runnerFile, "w")
    if rf then
        rf:write(bash_script)
        rf:close()
        os.execute("bash " .. runnerFile)
    end

    local f = io.open(tempCmdFile, "r")
    local cmd = f and f:read("*l") or ""
    if f then f:close() end

    if not directorioExiste(dirActual) then
        dirActual = subirHastaExistente(dirActual)
    end

    return cmd, dirActual
end
---------------------------------------------------------

----------- Variables de información ----------
local hostname = capturarComando("hostname")
local user = capturarComando("whoami")
local dirActual = getDirectorioInicial()

os.execute("clear")

-- Mostrar logo si existe
local logoName = config.Logo or "Logo"
local rutaLogo = infernalRoot .. "/" .. logoName
local logoFile = io.open(rutaLogo, "r")
if logoFile then
    local logo = logoFile:read("*all")
    logoFile:close()
    if logo then
        print(colores.rojo .. logo .. colores.reset)
    end
end

-- Ejecutar Fetch si está habilitado y existe
local showFetch = true
if config.ShowFetch ~= nil then
    showFetch = (config.ShowFetch:lower() == "true")
end

if showFetch then
    local fetchPath = infernalRoot .. "/Fetch"
    local fetchFile = io.open(fetchPath, "r")
    if fetchFile then
        fetchFile:close()
        os.execute("'" .. fetchPath:gsub("'", "'\\''") .. "'")
    end
end

-- Bucle principal
while true do
    local cmd, nuevoDir = leerComando(user, hostname, dirActual)
    dirActual = nuevoDir or dirActual

    if cmd and cmd ~= "" then
        if cmd == "exit" then
            print("Saliendo de Infernal...")
            break
        end

        if cmd == "ls" or cmd:match("^ls%s+") then
            local safeDir = dirActual:gsub("'", "'\\''")
            local args = cmd:match("^ls%s+(.*)$") or ""
            os.execute("cd '" .. safeDir .. "' && LS_COLORS='" .. lsColors .. "' ls " .. args .. " --color=auto")
            cmd = nil
        end

        if cmd then
            if cmd:match("^cd%s*") then
                if cmd == "cd" or cmd == "cd " then
                    dirActual = home
                else
                    local safeDir = dirActual:gsub("'", "'\\''")
                    local comando_eval = "cd '" .. safeDir .. "' && " .. cmd .. " && pwd"
                    local nuevo_dir = capturarComando(comando_eval)
                    if nuevo_dir and nuevo_dir ~= "" and not nuevo_dir:match("Error") then
                        dirActual = nuevo_dir
                    else
                        print("infernal: cd: No se pudo cambiar de directorio.")
                    end
                end
            else
                ejecutarComandoPersonalizado(cmd, dirActual)
            end
        end
    end

    -- Verificar después de cada iteración
    if not directorioExiste(dirActual) then
        dirActual = subirHastaExistente(dirActual)
    end
end

#!/bin/lua

-------- Configuración de la carpeta raíz de Infernal --------
local infernalRoot = os.getenv("HOME") .. "/.infernal"

----------- Instalación Automática (Primera Ejecución) -----
local function instalarEnPrimeraEjecucion()
    local home = os.getenv("HOME")
    local installDir = home .. "/.infernal"
    local lockFile = installDir .. "/.installed"
    
    -- Verificar si ya se ha instalado
    local f = io.open(lockFile, "r")
    if f then
        f:close()
        return  -- Ya instalado, continuar normalmente
    end
    
    -- Obtener el directorio del script original
    local scriptPath = arg[0]
    local scriptDir = scriptPath:gsub("/[^/]+$", "")
    
    -- Si no es una ruta absoluta, intentar obtenerla
    if not scriptDir:match("^/") then
        scriptDir = os.getenv("PWD") .. "/" .. scriptDir
    end
    
    print("\27[1;33m⚡ Primera ejecución detectada...\27[0m")
    print("\27[1;34m📦 Instalando Infernal en " .. installDir .. "...\27[0m")
    print("\27[1;36m   Desde: " .. scriptDir .. "\27[0m")
    
    -- Crear directorio de instalación
    os.execute("mkdir -p '" .. installDir:gsub("'", "'\\''") .. "'")
    
    -- Copiar TODO el contenido de la carpeta del proyecto
    -- EXCEPTO el infernal.lua (ya existe en su lugar)
    local copyCmd = "cd '" .. scriptDir:gsub("'", "'\\''") .. "' && find . -maxdepth 1 -type f -o -type d -not -name '.' -not -name 'infernal.lua' | xargs -I {} cp -r {} '" .. installDir:gsub("'", "'\\''") .. "/' 2>/dev/null; true"
    os.execute(copyCmd)
    
    -- Crear archivo de lock para marcar como instalado
    local lockF = io.open(lockFile, "w")
    if lockF then
        lockF:write("installed\n")
        lockF:close()
    end
    
    -- Hacer ejecutable el script principal
    os.execute("chmod +x '" .. installDir:gsub("'", "'\\''") .. "/infernal.lua' 2>/dev/null")
    os.execute("chmod +x '" .. installDir:gsub("'", "'\\''") .. "/apps'/* 2>/dev/null")
    
    print("\27[1;32m✓ Instalación completada!\27[0m")
    print("\27[36mPuedes ejecutar desde cualquier lugar: ~/.infernal/infernal.lua\27[0m\n")
end

-- Ejecutar instalación si es necesario
instalarEnPrimeraEjecucion()

----------- Dar permisos de ejecución automáticos --------
local function darPermisosApps()
    local appsDir = infernalRoot .. "/apps"
    -- Dar permisos de ejecución a todos los archivos en apps/
    os.execute("chmod +x '" .. appsDir:gsub("'", "'\\''") .. "'/* 2>/dev/null; true")
end

-- Ejecutar automáticamente cada vez que se inicia Infernal
darPermisosApps()
----------------------------------------------------------

----------- Paleta de Colores Disponibles ----------------
local colorMap = {
    black   = "\27[30m",
    red     = "\27[31m",
    green   = "\27[32m",
    yellow  = "\27[33m",
    blue    = "\27[34m",
    magenta = "\27[35m",
    cyan    = "\27[36m",
    white   = "\27[37m",
    orange  = "\27[38;5;208m",
    purple  = "\27[35m",
    gray    = "\27[37m",
}

----------- Variables de personalización ----------------
local colores = {
    azul  = "\27[34m",
    verde = "\27[32m",
    rojo  = "\27[31m",
    negro   = "\27[30m",
    amarillo= "\27[33m",
    magenta = "\27[35m",
    cian    = "\27[36m",
    blanco  = "\27[37m",

    azul_bold  = "\27[1;34m",
    verde_bold = "\27[1;32m",
    rojo_bold  = "\27[1;31m",
    negro_bold   = "\27[1;30m",
    amarillo_bold= "\27[1;33m",
    magenta_bold = "\27[1;35m",
    cian_bold    = "\27[1;36m",
    blanco_bold  = "\27[1;37m",

    bold  = "\27[1m",
    reset = "\27[0m"
}

----------- Funciones de Configuración ----
local function leerConfiguracion()
    local configFile = infernalRoot .. "/CONFIGURATION"
    local config = {}
    
    local f = io.open(configFile, "r")
    if not f then
        -- Crear configuración por defecto
        return {
            Folders = "blue",
            Symlinks = "orange",
            Files = "white",
            Executables = "green",
            Logo = "Logo",
            UserColor = "red",
            HostnameColor = "red",
            AtsingColor = "red",
            PwdColor = "blue",
            Root = infernalRoot
        }
    end
    
    for linea in f:lines() do
        if linea:match("=") and not linea:match("^%[") then
            local key, value = linea:match("^([^=]+)=(.+)$")
            if key and value then
                config[key:gsub("%s+$", "")] = value:gsub("%s+$", "")
            end
        end
    end
    f:close()
    
    return config
end

local function getColorCode(colorName)
    return colorMap[colorName] or colorMap["white"]
end

-- Cargar configuración
local config = leerConfiguracion()

----------- Funciones del Sistema -----------------------
local function capturarComando(comando)
    local pipe = io.popen(comando)
    if not pipe then return "" end
    local resultado = pipe:read("*all")
    pipe:close()
    return resultado:gsub("%s+$", "")
end

local function ejecutarEnTerminal(comando, dirActual)
    local safeDir = dirActual:gsub("'", "'\\''")
    os.execute("cd '" .. safeDir .. "' && " .. comando)
end

-- Función de ejecución con prioridad: ~/.infernal/apps/ > ~/.local/bin/ > PATH
local function ejecutarComandoPersonalizado(cmd, dirActual)
    local base = cmd:match("^(%S+)")
    if not base then return end
    local home = os.getenv("HOME") or "~"
    local safeDir = dirActual:gsub("'", "'\\''")
    local args = cmd:sub(#base + 1)
    local ruta_ejecutable = nil

    if not base:find("/") then
        -- 1. Buscar en infernalRoot/apps/
        local app_path = infernalRoot .. "/apps/" .. base
        local safe_app = app_path:gsub("'", "'\\''")
        local test_result = os.execute("test -x '" .. safe_app .. "'")
        if test_result == 0 or test_result == true then
            ruta_ejecutable = app_path
        else
            -- 2. Buscar en ~/.local/bin/
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
---------------------------------------------------------

-------------- Funciones para el Shell ------------------
local function getDirectorioInicial()
    return capturarComando("pwd")
end

local function leerComando(user, hostname, dirActual)
    local home = os.getenv("HOME") or "~"
    local historyFile = infernalRoot .. "/History"
    local tempCmdFile = "/tmp/.infernal_cmd"
    local runnerFile = "/tmp/.infernal_runner.sh"
    local safeDir = dirActual:gsub("'", "'\\''")

    local display_dir = dirActual
    if home ~= "" and dirActual:find(home, 1, true) == 1 then
        display_dir = dirActual:gsub("^" .. home, "~")
    end
    local safeDisplayDir = display_dir:gsub("'", "'\\''")

    -- Usar colores de configuración
    local userColor = getColorCode(config.UserColor)
    local hostColor = getColorCode(config.HostnameColor)
    local atColor = getColorCode(config.AtsingColor)
    local pwdColor = getColorCode(config.PwdColor)

    local pUser = "\1" .. colores.bold .. userColor .. "\2" .. user .. "\1" .. colores.reset .. "\2"
    local pArroba = "\1" .. atColor .. "\2@\1" .. colores.reset .. "\2"
    local pHost = "\1" .. colores.bold .. hostColor .. "\2" .. hostname .. "\1" .. colores.reset .. "\2"
    local pDir = "\1" .. colores.bold .. pwdColor .. "\2" .. safeDisplayDir .. "\1" .. colores.reset .. "\2"

    local promptFinal = pUser .. pArroba .. pHost .. ":" .. pDir .. "$ "

    os.remove(tempCmdFile)

    local bash_script = string.format([[
#!/bin/bash
cd '%s'
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

    return cmd
end
---------------------------------------------------------

----------- Funciones de Gestión de archivos ------------
local function leerArchivo(ruta)
    local file = io.open(ruta, "r")
    if not file then return nil end
    local contenido = file:read("*all")
    file:close()
    return contenido
end

local function crearArchivo(ruta)
    local file = io.open(ruta, "r")
    if file then
        file:close()
        return false, "El archivo ya existe: " .. ruta
    end
    local newFile, err = io.open(ruta, "w")
    if not newFile then
        return false, "No se pudo crear el archivo: " .. err
    end
    newFile:close()
    return true
end
----------------------------------------------------------

-------------- Variables de información ------------------
local hostname = capturarComando("hostname")
local user = capturarComando("whoami")
local home = os.getenv("HOME")
local rutaLogo = infernalRoot .. "/" .. config.Logo
local logo = leerArchivo(rutaLogo)
local dirActual = getDirectorioInicial()

-- Crear automáticamente la estructura de carpetas de Infernal
os.execute("mkdir -p '" .. infernalRoot:gsub("'", "'\\''") .. "/apps'")
----------------------------------------------------------

-- Limpiar la terminal para una experiencia inmersiva
os.execute("clear")

if logo then
    print(colores.rojo .. logo .. colores.reset)
end

-- =====================================================
--  EJECUTAR FETCH DESPUÉS DEL LOGO
-- =====================================================
local fetchPath = infernalRoot .. "/Fetch"
local fetchFile = io.open(fetchPath, "r")
if fetchFile then
    fetchFile:close()
    -- Ejecutar Fetch y mostrar su salida
    os.execute("'" .. fetchPath:gsub("'", "'\\''") .. "'")
else
    print(colores.amarillo .. "Fetch no encontrado en " .. fetchPath .. colores.reset)
end
-- =====================================================

while true do
    local cmd = leerComando(user, hostname, dirActual)

    if cmd and cmd ~= "" then
        if cmd == "exit" then
            print("Saliendo de Infernal...")
            break
        end

        -- Inyectamos colores personalizados en ls
        if cmd == "ls" or cmd:match("^ls%s+") then
            local lsColors = "di=1;34:ex=1;32:ln=1;33:fi=1;37"
            local safeDir = dirActual:gsub("'", "'\\''")
            local args = cmd:match("^ls%s+(.*)$") or ""
            os.execute("cd '" .. safeDir .. "' && LS_COLORS='" .. lsColors .. "' ls " .. args .. " --color=auto")
            cmd = nil
        end

        -- Lógica para cambiar de directorio
        if cmd then
            if cmd:match("^cd%s*") then
                local safeDir = dirActual:gsub("'", "'\\''")
                local comando_eval = "cd '" .. safeDir .. "' && " .. cmd .. " && pwd"
                local nuevo_dir = capturarComando(comando_eval)
                if nuevo_dir and nuevo_dir ~= "" and not nuevo_dir:match("Error") then
                    dirActual = nuevo_dir
                else
                    print("infernal: cd: No se pudo cambiar de directorio.")
                end
            else
                ejecutarComandoPersonalizado(cmd, dirActual)
            end
        end
    end
end

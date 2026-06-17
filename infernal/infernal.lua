#!/bin/lua

----------- Configuración de la carpeta raíz de Infernal --------
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
    print("\27[1;36m    Desde: " .. scriptDir .. "\27[0m")
    
    -- Crear directorio de instalación
    os.execute("mkdir -p '" .. installDir:gsub("'", "'\\''") .. "'")
    
    -- COPIA CORREGIDA: Usa -mindepth 1 para ignorar '.' y -exec para manejar carpetas correctamente
    local copyCmd = "cd '" .. scriptDir:gsub("'", "'\\''") .. "' && find . -maxdepth 1 -mindepth 1 ! -name 'infernal.lua' -exec cp -r {} '" .. installDir:gsub("'", "'\\''") .. "/' \\; 2>/dev/null; true"
    os.execute(copyCmd)
    
    -- Crear archivo de lock para marcar como instalado
    local lockF = io.open(lockFile, "w")
    if lockF then
        lockF:write("installed\n")
        lockF:close()
    end
    
    -- Hacer ejecutable el script principal y las apps
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
    os.execute("chmod +x '" .. appsDir:gsub("'", "'\\''") .. "'/* 2>/dev/null; true")
end

darPermisosApps()

----------- Paleta de Colores y Configuración -----------
local colorMap = {
    black   = "\27[30m", red = "\27[31m", green = "\27[32m", yellow = "\27[33m",
    blue    = "\27[34m", magenta = "\27[35m", cyan = "\27[36m", white = "\27[37m",
    orange  = "\27[38;5;208m",
}

local colores = {
    azul = "\27[34m", verde = "\27[32m", rojo = "\27[31m", negro = "\27[30m",
    amarillo = "\27[33m", magenta = "\27[35m", cian = "\27[36m", blanco = "\27[37m",
    azul_bold = "\27[1;34m", verde_bold = "\27[1;32m", rojo_bold = "\27[1;31m",
    negro_bold = "\27[1;30m", amarillo_bold = "\27[1;33m", magenta_bold = "\27[1;35m",
    cian_bold = "\27[1;36m", blanco_bold = "\27[1;37m",
    bold = "\27[1m", reset = "\27[0m"
}

local function leerConfiguracion()
    local configFile = infernalRoot .. "/CONFIGURATION"
    local config = {
        Folders="blue", Symlinks="orange", Files="white", Executables="green",
        Logo="Logo", UserColor="red", HostnameColor="red", AtsingColor="red",
        PwdColor="blue", Root=infernalRoot
    }
    local f = io.open(configFile, "r")
    if f then
        for linea in f:lines() do
            local key, value = linea:match("^([^=]+)=(.+)$")
            if key then config[key:gsub("%s+$", "")] = value:gsub("%s+$", "") end
        end
        f:close()
    end
    return config
end

local config = leerConfiguracion()

local function getColorCode(colorName) return colorMap[colorName] or colorMap["white"] end

----------- Funciones del Sistema -----------------------
local function capturarComando(comando)
    local pipe = io.popen(comando)
    if not pipe then return "" end
    local res = pipe:read("*all")
    pipe:close()
    return res:gsub("%s+$", "")
end

local function ejecutarComandoPersonalizado(cmd, dirActual)
    local base = cmd:match("^(%S+)")
    if not base then return end
    local args = cmd:sub(#base + 1)
    local ruta_ejecutable = nil

    if not base:find("/") then
        local app_path = infernalRoot .. "/apps/" .. base
        if os.execute("test -x '" .. app_path:gsub("'", "'\\''") .. "'") == 0 then
            ruta_ejecutable = app_path
        end
    end

    local final = ruta_ejecutable and ("'" .. ruta_ejecutable:gsub("'", "'\\''") .. "'" .. args) or cmd
    os.execute("cd '" .. dirActual:gsub("'", "'\\''") .. "' && " .. final)
end

----------- Shell y Bucle Principal ---------------------
local hostname = capturarComando("hostname")
local user = capturarComando("whoami")
local dirActual = capturarComando("pwd")

os.execute("clear")
local logo = io.open(infernalRoot .. "/" .. config.Logo, "r")
if logo then print(colores.rojo .. logo:read("*all") .. colores.reset); logo:close() end

while true do
    local prompt = string.format("%s%s@%s:%s$ ", colores.bold, user, hostname, dirActual)
    io.write(prompt)
    io.flush()
    
    local cmd = io.read()
    if not cmd or cmd == "exit" then break end
    
    if cmd:match("^cd%s*") then
        local target = cmd:match("^cd%s+(.*)$") or os.getenv("HOME")
        if os.execute("cd '" .. target:gsub("'", "'\\''") .. "'") == 0 then
            dirActual = capturarComando("pwd")
        else
            print("Directorio no encontrado")
        end
    elseif cmd ~= "" then
        ejecutarComandoPersonalizado(cmd, dirActual)
    end
end

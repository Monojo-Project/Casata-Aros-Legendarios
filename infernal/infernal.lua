#!/usr/bin/env lua

-- Script para configurar Infernal desde la CLI
-- Uso: config [opción]

local infernalRoot = os.getenv("HOME") .. "/.infernal"

----------- Colores para la interfaz ----
local colors = {
    reset   = "\27[0m",
    bold    = "\27[1m",
    red     = "\27[31m",
    green   = "\27[32m",
    yellow  = "\27[33m",
    blue    = "\27[34m",
    magenta = "\27[35m",
    cyan    = "\27[36m",
    white   = "\27[37m",
}

----------- Paleta de colores disponibles ----
local colorPalette = {
    "black",
    "red",
    "green",
    "yellow",
    "blue",
    "magenta",
    "cyan",
    "white",
    "orange",
    "purple",
    "gray",
}

----------- Funciones Auxiliares ----
local function leerConfiguracion()
    local configFile = infernalRoot .. "/CONFIGURATION"
    local config = {}
    
    local f = io.open(configFile, "r")
    if not f then
        return nil
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

local function guardarConfiguracion(config)
    local configFile = infernalRoot .. "/CONFIGURATION"
    local f = io.open(configFile, "w")
    if not f then
        print(colors.red .. "❌ Error: No se pudo abrir el archivo de configuración" .. colors.reset)
        return false
    end
    
    -- Función auxiliar para evitar errores nil y poner un valor por defecto
    local function getVal(key) return config[key] or "white" end

    f:write("[Infernal configuration]\n\n")
    f:write("Folders=" .. getVal("Folders") .. "\n")
    f:write("Symlinks=" .. getVal("Symlinks") .. "\n")
    f:write("Files=" .. getVal("Files") .. "\n")
    f:write("Executables=" .. getVal("Executables") .. "\n\n")
    f:write("Logo=" .. (config.Logo or "Logo1") .. "\n")
    f:write("UserColor=" .. getVal("UserColor") .. "\n")
    f:write("HostnameColor=" .. getVal("HostnameColor") .. "\n")
    f:write("AtsingColor=" .. getVal("AtsingColor") .. "\n")
    f:write("PwdColor=" .. getVal("PwdColor") .. "\n\n")
    f:write("Root=" .. (config.Root or "false") .. "\n")
    
    f:close()
    return true
end

local function limpiarPantalla()
    os.execute("clear")
end

local function mostrarEncabezado()
    print(colors.bold .. colors.cyan .. "╔════════════════════════════════════════╗" .. colors.reset)
    print(colors.bold .. colors.cyan .. "║   " .. colors.magenta .. "⚙️  CONFIGURADOR DE INFERNAL" .. colors.cyan .. "   ║" .. colors.reset)
    print(colors.bold .. colors.cyan .. "╚════════════════════════════════════════╝" .. colors.reset)
    print()
end

local function mostrarMenu()
    mostrarEncabezado()
    print(colors.bold .. "¿Qué quieres cambiar?" .. colors.reset)
    print()
    print(colors.cyan .. "  [1]" .. colors.reset .. " Color de carpetas (Folders)")
    print(colors.cyan .. "  [2]" .. colors.reset .. " Color de enlaces simbólicos (Symlinks)")
    print(colors.cyan .. "  [3]" .. colors.reset .. " Color de archivos (Files)")
    print(colors.cyan .. "  [4]" .. colors.reset .. " Color de ejecutables (Executables)")
    print(colors.cyan .. "  [5]" .. colors.reset .. " Logo")
    print(colors.cyan .. "  [6]" .. colors.reset .. " Color del usuario (UserColor)")
    print(colors.cyan .. "  [7]" .. colors.reset .. " Color del hostname (HostnameColor)")
    print(colors.cyan .. "  [8]" .. colors.reset .. " Color del @ (AtsingColor)")
    print(colors.cyan .. "  [9]" .. colors.reset .. " Color del directorio (PwdColor)")
    print()
    print(colors.yellow .. "  [0]" .. colors.reset .. " Ver configuración actual")
    print(colors.red .. "  [q]" .. colors.reset .. " Salir")
    print()
end

local function mostrarPaletaColores()
    print(colors.bold .. "Colores disponibles:" .. colors.reset)
    print()
    for i, color in ipairs(colorPalette) do
        print(colors.cyan .. "  [" .. i .. "]" .. colors.reset .. " " .. color)
    end
    print()
end

local function seleccionarColor()
    mostrarPaletaColores()
    
    while true do
        io.write(colors.bold .. "Selecciona un color (1-" .. #colorPalette .. "): " .. colors.reset)
        local opcion = io.read()
        local num = tonumber(opcion)
        
        if num and num >= 1 and num <= #colorPalette then
            return colorPalette[num]
        else
            print(colors.red .. "❌ Opción no válida, intenta de nuevo." .. colors.reset)
        end
    end
end

local function seleccionarLogo()
    print(colors.bold .. "Logos disponibles:" .. colors.reset)
    print()
    
    -- Listar archivos en ~/.infernal/ que empiecen con "Logo"
    local pipe = io.popen("ls -1 " .. infernalRoot .. "/Logo* 2>/dev/null | xargs -I {} basename {}")
    local logos = {}
    
    if pipe then
        for linea in pipe:lines() do
            table.insert(logos, linea)
        end
        pipe:close()
    end
    
    if #logos == 0 then
        print(colors.red .. "⚠️  No se encontraron logos disponibles" .. colors.reset)
        return nil
    end
    
    for i, logo in ipairs(logos) do
        print(colors.cyan .. "  [" .. i .. "]" .. colors.reset .. " " .. logo)
    end
    print()
    
    while true do
        io.write(colors.bold .. "Selecciona un logo (1-" .. #logos .. "): " .. colors.reset)
        local opcion = io.read()
        local num = tonumber(opcion)
        
        if num and num >= 1 and num <= #logos then
            return logos[num]
        else
            print(colors.red .. "❌ Opción no válida, intenta de nuevo." .. colors.reset)
        end
    end
end

local function pausar()
    io.write("\n" .. colors.bold .. "Presiona Enter para continuar..." .. colors.reset)
    io.read()
end

local function mostrarConfiguracionActual(config)
    limpiarPantalla()
    mostrarEncabezado()
    
    print(colors.bold .. colors.yellow .. "Configuración Actual:" .. colors.reset)
    print()
    print(colors.cyan .. "  Folders:       " .. colors.reset .. (config.Folders or "No definido"))
    print(colors.cyan .. "  Symlinks:      " .. colors.reset .. (config.Symlinks or "No definido"))
    print(colors.cyan .. "  Files:         " .. colors.reset .. (config.Files or "No definido"))
    print(colors.cyan .. "  Executables:   " .. colors.reset .. (config.Executables or "No definido"))
    print()
    print(colors.cyan .. "  Logo:          " .. colors.reset .. (config.Logo or "No definido"))
    print(colors.cyan .. "  UserColor:     " .. colors.reset .. (config.UserColor or "No definido"))
    print(colors.cyan .. "  HostnameColor: " .. colors.reset .. (config.HostnameColor or "No definido"))
    print(colors.cyan .. "  AtsingColor:   " .. colors.reset .. (config.AtsingColor or "No definido"))
    print(colors.cyan .. "  PwdColor:      " .. colors.reset .. (config.PwdColor or "No definido"))
    print(colors.cyan .. "  Root:          " .. colors.reset .. (config.Root or "No definido"))
    
    pausar()
end

----------- Función Principal ----
local function main()
    local config = leerConfiguracion()
    
    if not config then
        print(colors.red .. "❌ Error: No se encontró el archivo de configuración en " .. infernalRoot .. colors.reset)
        os.exit(1)
    end
    
    while true do
        limpiarPantalla()
        mostrarMenu()
        
        io.write(colors.bold .. "Opción: " .. colors.reset)
        local opcion = io.read():lower()
        
        if opcion == "q" then
            print(colors.green .. "✓ Saliendo del configurador..." .. colors.reset)
            break
        elseif opcion == "0" then
            mostrarConfiguracionActual(config)
        elseif opcion == "1" then
            print()
            local nuevoColor = seleccionarColor()
            config.Folders = nuevoColor
            guardarConfiguracion(config)
            print(colors.green .. "✓ Color de carpetas actualizado a: " .. nuevoColor .. colors.reset)
            pausar()
        elseif opcion == "2" then
            print()
            local nuevoColor = seleccionarColor()
            config.Symlinks = nuevoColor
            guardarConfiguracion(config)
            print(colors.green .. "✓ Color de enlaces actualizado a: " .. nuevoColor .. colors.reset)
            pausar()
        elseif opcion == "3" then
            print()
            local nuevoColor = seleccionarColor()
            config.Files = nuevoColor
            guardarConfiguracion(config)
            print(colors.green .. "✓ Color de archivos actualizado a: " .. nuevoColor .. colors.reset)
            pausar()
        elseif opcion == "4" then
            print()
            local nuevoColor = seleccionarColor()
            config.Executables = nuevoColor
            guardarConfiguracion(config)
            print(colors.green .. "✓ Color de ejecutables actualizado a: " .. nuevoColor .. colors.reset)
            pausar()
        elseif opcion == "5" then
            print()
            local nuevoLogo = seleccionarLogo()
            if nuevoLogo then
                config.Logo = nuevoLogo
                guardarConfiguracion(config)
                print(colors.green .. "✓ Logo actualizado a: " .. nuevoLogo .. colors.reset)
            end
            pausar()
        elseif opcion == "6" then
            print()
            local nuevoColor = seleccionarColor()
            config.UserColor = nuevoColor
            guardarConfiguracion(config)
            print(colors.green .. "✓ Color de usuario actualizado a: " .. nuevoColor .. colors.reset)
            pausar()
        elseif opcion == "7" then
            print()
            local nuevoColor = seleccionarColor()
            config.HostnameColor = nuevoColor
            guardarConfiguracion(config)
            print(colors.green .. "✓ Color de hostname actualizado a: " .. nuevoColor .. colors.reset)
            pausar()
        elseif opcion == "8" then
            print()
            local nuevoColor = seleccionarColor()
            config.AtsingColor = nuevoColor
            guardarConfiguracion(config)
            print(colors.green .. "✓ Color del @ actualizado a: " .. nuevoColor .. colors.reset)
            pausar()
        elseif opcion == "9" then
            print()
            local nuevoColor = seleccionarColor()
            config.PwdColor = nuevoColor
            guardarConfiguracion(config)
            print(colors.green .. "✓ Color del directorio actualizado a: " .. nuevoColor .. colors.reset)
            pausar()
        else
            print(colors.red .. "❌ Opción no válida, intenta de nuevo." .. colors.reset)
            pausar()
        end
    end
end

-- Ejecutar
main()

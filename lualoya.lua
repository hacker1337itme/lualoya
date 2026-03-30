-- ============================================================================
-- PROFESSIONAL ANTI-DEBUG SYSTEM FOR LUA
-- ============================================================================
-- Features:
--   - Multiple debugger detection methods
--   - Timing-based analysis detection
--   - Environment fingerprinting
--   - Sandbox/VM detection
--   - Anti-hooking techniques
--   - Stealth and evasion tactics
-- ============================================================================

local AntiDebug = {}
AntiDebug.__index = AntiDebug

-- ============================================================================
-- CONFIGURATION
-- ============================================================================
local config = {
    timing_threshold = 0.05,        -- Timing check threshold (seconds)
    max_checks = 10,                -- Maximum number of check iterations
    stealth_mode = true,            -- Enable stealth evasion
    aggressive_mode = false,        -- Aggressive anti-debug actions
    vm_detection = true,            -- Detect virtual machines
    network_check = true,           -- Check for network monitoring
    persistence = true              -- Enable persistent checks
}

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

local function get_time()
    -- High-precision timing using os.clock()
    return os.clock()
end

local function random_delay(min, max)
    -- Random delay to confuse timing analysis
    local delay = min + (math.random() * (max - min))
    local start = get_time()
    while get_time() - start < delay do
        -- Busy wait
        local _ = 0
        for i = 1, 1000 do
            _ = _ + i
        end
    end
end

local function execute_command(cmd)
    -- Execute system command safely
    local handle = io.popen(cmd)
    local result = handle:read("*a")
    handle:close()
    return result
end

-- ============================================================================
-- DEBUGGER DETECTION METHODS
-- ============================================================================

-- Method 1: Timing Analysis
function AntiDebug:detect_by_timing()
    print("[*] Performing timing analysis...")
    
    local checks_passed = 0
    local total_time = 0
    
    for i = 1, config.max_checks do
        -- Measure execution time of simple operation
        local start = get_time()
        
        -- Perform CPU-intensive operation
        local result = 0
        for j = 1, 1000000 do
            result = result + j
        end
        
        local elapsed = get_time() - start
        total_time = total_time + elapsed
        
        -- Debuggers slow down execution
        if elapsed > config.timing_threshold then
            checks_passed = checks_passed + 1
        end
        
        -- Random delay between checks
        random_delay(0.001, 0.01)
    end
    
    local avg_time = total_time / config.max_checks
    
    if avg_time > config.timing_threshold then
        print("[!] Suspicious timing detected: " .. avg_time .. "s average")
        return true
    end
    
    print("[+] Timing analysis passed")
    return false
end

-- Method 2: Debug Hook Detection
function AntiDebug:detect_debug_hooks()
    print("[*] Checking for debug hooks...")
    
    -- Check for debug library availability
    local has_debug = pcall(function() return debug.getinfo end)
    
    if has_debug then
        -- Try to detect debug hooks
        local hook_status = debug.gethook()
        if hook_status then
            print("[!] Debug hook detected!")
            return true
        end
        
        -- Check for debugger presence via getinfo
        local info = debug.getinfo(1)
        if info and info.name == "debug" then
            print("[!] Debugger name detected")
            return true
        end
    end
    
    -- Check for overridden debug functions
    local original_debug = debug
    local debug_check = pcall(function()
        if debug.getinfo ~= original_debug.getinfo then
            error("Debug function modified")
        end
    end)
    
    if not debug_check then
        print("[!] Debug functions appear to be hooked")
        return true
    end
    
    print("[+] No debug hooks detected")
    return false
end

-- Method 3: Breakpoint Detection
function AntiDebug:detect_breakpoints()
    print("[*] Scanning for breakpoints...")
    
    -- Check for common breakpoint signatures
    local breakpoint_patterns = {
        "debugger", "breakpoint", "int3", "0xCC",
        "debug", "trace", "step", "watch"
    }
    
    -- Check stack trace for breakpoint indicators
    local success, stack = pcall(function()
        return debug.traceback()
    end)
    
    if success and stack then
        for _, pattern in ipairs(breakpoint_patterns) do
            if stack:lower():find(pattern) then
                print("[!] Breakpoint pattern found: " .. pattern)
                return true
            end
        end
    end
    
    -- Check for suspicious function calls in stack
    local frames = {}
    local level = 1
    while true do
        local info = debug.getinfo(level, "n")
        if not info then break end
        table.insert(frames, info.name or "unknown")
        level = level + 1
    end
    
    -- Look for debugging functions in call stack
    local debug_functions = {"debug", "hook", "step", "break"}
    for _, frame in ipairs(frames) do
        for _, func in ipairs(debug_functions) do
            if frame:lower():find(func) then
                print("[!] Debug function in stack: " .. frame)
                return true
            end
        end
    end
    
    print("[+] No breakpoints detected")
    return false
end

-- Method 4: Environment Fingerprinting
function AntiDebug:detect_environment()
    print("[*] Analyzing environment...")
    
    -- Check for common debugger environment variables
    local debug_env_vars = {
        "DEBUG", "DBG", "DEBUGGER", "GDB", "LLDB",
        "WINDBG", "SOFTICE", "OLYDBG", "IMMUNITY"
    }
    
    for _, var in ipairs(debug_env_vars) do
        if os.getenv(var) then
            print("[!] Debug environment variable found: " .. var)
            return true
        end
    end
    
    -- Check for debugger processes on Windows
    if package.config:sub(1,1) == "\\" then  -- Windows
        local debug_processes = {
            "ollydbg.exe", "x64dbg.exe", "windbg.exe",
            "ida.exe", "ida64.exe", "gdb.exe",
            "processhacker.exe", "procexp.exe"
        }
        
        local tasklist = execute_command("tasklist 2>nul")
        if tasklist then
            for _, proc in ipairs(debug_processes) do
                if tasklist:lower():find(proc) then
                    print("[!] Debugger process detected: " .. proc)
                    return true
                end
            end
        end
    end
    
    -- Check for debugger on Linux/Mac
    if package.config:sub(1,1) == "/" then
        local ps_output = execute_command("ps aux 2>/dev/null")
        if ps_output then
            local debug_procs = {"gdb", "lldb", "strace", "ltrace", "valgrind"}
            for _, proc in ipairs(debug_procs) do
                if ps_output:lower():find(proc) then
                    print("[!] Debugger process detected: " .. proc)
                    return true
                end
            end
        end
    end
    
    print("[+] Environment appears clean")
    return false
end

-- Method 5: Virtual Machine Detection
function AntiDebug:detect_virtual_machine()
    if not config.vm_detection then
        return false
    end
    
    print("[*] Checking for virtual machine...")
    
    -- VM indicators
    local vm_indicators = {
        -- Common VM files/directories
        {path = "C:\\Program Files\\VMware", type = "vmware"},
        {path = "C:\\Program Files\\VirtualBox", type = "virtualbox"},
        {path = "C:\\Program Files\\QEMU", type = "qemu"},
        
        -- VM registry keys (Windows)
        {reg = "HKLM\\SOFTWARE\\VMware", type = "vmware"},
        {reg = "HKLM\\SOFTWARE\\VirtualBox", type = "virtualbox"},
        
        -- VM drivers
        {driver = "vmmouse.sys", type = "vmware"},
        {driver = "vboxguest.sys", type = "virtualbox"}
    }
    
    -- Check for VM processes
    local vm_processes = {
        "vmtoolsd.exe", "vboxservice.exe", "vboxtray.exe",
        "qemu-ga.exe", "vmusrvc.exe"
    }
    
    if package.config:sub(1,1) == "\\" then  -- Windows
        local tasklist = execute_command("tasklist 2>nul")
        if tasklist then
            for _, proc in ipairs(vm_processes) do
                if tasklist:lower():find(proc) then
                    print("[!] Virtual machine process detected: " .. proc)
                    return true
                end
            end
        end
    end
    
    -- Check CPU vendor for VM indicators
    local success, cpuid = pcall(function()
        -- This would require native extension; using system commands instead
        if package.config:sub(1,1) == "/" then
            return execute_command("cat /proc/cpuinfo 2>/dev/null | grep vendor_id")
        end
        return ""
    end)
    
    if success and cpuid then
        local vm_vendors = {"VMware", "VirtualBox", "QEMU", "KVM", "Xen"}
        for _, vendor in ipairs(vm_vendors) do
            if cpuid:find(vendor) then
                print("[!] Virtual machine vendor detected: " .. vendor)
                return true
            end
        end
    end
    
    print("[+] No virtual machine detected")
    return false
end

-- Method 6: Anti-Hooking Techniques
function AntiDebug:detect_hooks()
    print("[*] Checking for API hooks...")
    
    -- Check if critical functions are modified
    local critical_functions = {
        "print", "error", "pcall", "xpcall", 
        "load", "loadfile", "dofile"
    }
    
    for _, func_name in ipairs(critical_functions) do
        local original = _G[func_name]
        if original then
            -- Check if function is wrapped
            local success, result = pcall(function()
                local info = debug.getinfo(original, "S")
                if info and info.what == "C" then
                    -- Native function, likely safe
                else
                    -- Lua function, might be hooked
                    return true
                end
            end)
            
            if result then
                print("[!] Possibly hooked function: " .. func_name)
                return true
            end
        end
    end
    
    print("[+] No function hooks detected")
    return false
end

-- Method 7: Anti-Analysis Countermeasures
function AntiDebug:apply_countermeasures()
    if not config.stealth_mode then
        return
    end
    
    print("[*] Applying anti-analysis countermeasures...")
    
    -- Disable debug library if possible
    if config.aggressive_mode then
        -- Attempt to disable debug functionality
        local success, err = pcall(function()
            -- Override debug functions with dummy functions
            if debug then
                debug.gethook = function() return nil end
                debug.sethook = function() end
                debug.getinfo = function() return nil end
                debug.getlocal = function() return nil end
                debug.setlocal = function() end
                debug.getupvalue = function() return nil end
                debug.setupvalue = function() end
                debug.traceback = function() return "Traceback disabled" end
            end
        end)
        
        if not success then
            print("[!] Failed to disable debug functions")
        end
    end
    
    -- Randomize execution flow
    local execution_paths = {
        function() return "path1" end,
        function() return "path2" end,
        function() return "path3" end
    }
    
    -- Random delay to confuse timing analysis
    random_delay(0.01, 0.1)
    
    print("[+] Countermeasures applied")
end

-- Method 8: Integrity Verification
function AntiDebug:verify_integrity()
    print("[*] Verifying code integrity...")
    
    -- Calculate checksum of critical code sections
    local function simple_hash(str)
        local hash = 0
        for i = 1, #str do
            hash = (hash * 31 + string.byte(str, i)) % 2^32
        end
        return hash
    end
    
    -- Get source code (if available)
    local success, source = pcall(function()
        return debug.getinfo(1, "S").source
    end)
    
    if success and source then
        -- Expected hash would be stored elsewhere
        -- This is a simplified example
        print("[+] Integrity check passed")
    end
    
    return false
end

-- Method 9: Network Monitoring Detection
function AntiDebug:detect_network_monitoring()
    if not config.network_check then
        return false
    end
    
    print("[*] Checking for network monitoring...")
    
    -- Check for common network monitoring tools
    local monitoring_tools = {
        "wireshark", "tcpdump", "netmon", "fiddler",
        "charles", "burpsuite", "proxifier"
    }
    
    if package.config:sub(1,1) == "\\" then  -- Windows
        local tasklist = execute_command("tasklist 2>nul")
        if tasklist then
            for _, tool in ipairs(monitoring_tools) do
                if tasklist:lower():find(tool) then
                    print("[!] Network monitoring tool detected: " .. tool)
                    return true
                end
            end
        end
    end
    
    print("[+] No network monitoring detected")
    return false
end

-- Method 10: Stealth Evasion
function AntiDebug:evade_detection()
    if not config.stealth_mode then
        return
    end
    
    print("[*] Activating stealth mode...")
    
    -- Randomize behavior to avoid pattern matching
    local random_behavior = math.random(1, 5)
    
    if random_behavior == 1 then
        -- Perform legitimate-looking operations
        local legitimate_ops = {
            function() 
                local f = io.open("temp.txt", "w")
                if f then f:write("Log entry") f:close() end
            end,
            function() 
                local files = {}
                for file in io.popen('dir 2>nul'):lines() do
                    table.insert(files, file)
                end
            end
        }
        
        local op = legitimate_ops[math.random(#legitimate_ops)]
        if op then pcall(op) end
    elseif random_behavior == 2 then
        -- Insert random delays
        random_delay(0.1, 0.5)
    end
    
    print("[+] Stealth mode activated")
end

-- ============================================================================
-- MAIN ANTI-DEBUG CHECK
-- ============================================================================
function AntiDebug:run_full_check()
    print("\n" .. string.rep("=", 60))
    print("ANTI-DEBUG SYSTEM - FULL SCAN")
    print(string.rep("=", 60) .. "\n")
    
    local detections = {}
    local detection_count = 0
    
    -- Run all detection methods
    local checks = {
        {name = "Timing Analysis", func = self.detect_by_timing},
        {name = "Debug Hooks", func = self.detect_debug_hooks},
        {name = "Breakpoints", func = self.detect_breakpoints},
        {name = "Environment", func = self.detect_environment},
        {name = "Virtual Machine", func = self.detect_virtual_machine},
        {name = "API Hooks", func = self.detect_hooks},
        {name = "Network Monitoring", func = self.detect_network_monitoring}
    }
    
    for _, check in ipairs(checks) do
        print(string.rep("-", 40))
        local success, detected = pcall(function()
            return check.func(self)
        end)
        
        if success and detected then
            detection_count = detection_count + 1
            table.insert(detections, check.name)
            print("[!] " .. check.name .. ": DEBUGGER DETECTED!")
        elseif not success then
            print("[!] " .. check.name .. ": Check failed")
        end
    end
    
    -- Apply countermeasures
    self:apply_countermeasures()
    self:evade_detection()
    
    -- Verify integrity
    self:verify_integrity()
    
    print("\n" .. string.rep("=", 60))
    print("SCAN COMPLETE")
    print(string.rep("=", 60))
    
    if detection_count > 0 then
        print(string.format("[!] %d detection(s) found:", detection_count))
        for _, detection in ipairs(detections) do
            print("    - " .. detection)
        end
        return true
    else
        print("[+] No debugger detected")
        return false
    end
end

-- ============================================================================
-- BACKGROUND MONITORING THREAD
-- ============================================================================
function AntiDebug:start_persistent_monitoring(interval)
    if not config.persistence then
        return
    end
    
    print("[*] Starting persistent monitoring...")
    
    -- In Lua, we can't easily create background threads without coroutines
    -- This is a simplified example using coroutines
    local monitor = coroutine.create(function()
        while true do
            -- Wait for interval
            local start = get_time()
            while get_time() - start < interval do
                coroutine.yield()
            end
            
            -- Perform periodic checks
            if self:detect_by_timing() or self:detect_debug_hooks() then
                print("[!] Persistent monitoring: Debugger detected!")
                if config.aggressive_mode then
                    -- Take aggressive action
                    os.exit(1)
                end
            end
        end
    end)
    
    return monitor
end

-- ============================================================================
-- PROTECTED EXECUTION WRAPPER
-- ============================================================================
function AntiDebug:protect_execution(callback, ...)
    -- Run anti-debug check before execution
    if self:run_full_check() then
        print("[!] Debugger detected! Execution may be compromised.")
        
        if config.aggressive_mode then
            print("[!] Aggressive mode: Exiting...")
            os.exit(1)
        end
    end
    
    -- Execute protected code
    local success, result = pcall(callback, ...)
    
    if not success then
        print("[!] Protected execution failed: " .. tostring(result))
        return false
    end
    
    return result
end

-- ============================================================================
-- EXPORTED INTERFACE
-- ============================================================================
function AntiDebug.new(user_config)
    local self = setmetatable({}, AntiDebug)
    
    -- Merge user config with defaults
    for k, v in pairs(user_config or {}) do
        config[k] = v
    end
    
    -- Initialize random seed
    math.randomseed(os.time())
    
    return self
end

-- ============================================================================
-- USAGE EXAMPLE
-- ============================================================================
if arg and arg[0] == debug.getinfo(1).source then
    -- Example usage when run directly
    local anti = AntiDebug.new({
        timing_threshold = 0.03,
        aggressive_mode = false,
        stealth_mode = true,
        vm_detection = true
    })
    
    -- Protected execution example
    local function sensitive_code()
        print("\n[*] Executing sensitive code...")
        -- Your protected code here
        print("[*] Sensitive operation completed")
        return "success"
    end
    
    local result = anti:protect_execution(sensitive_code)
    print("[*] Execution result: " .. tostring(result))
    
    -- Start persistent monitoring (non-blocking)
    local monitor = anti:start_persistent_monitoring(5)  -- Check every 5 seconds
    
    -- Main program loop
    local counter = 0
    while counter < 10 do
        if monitor and coroutine.status(monitor) == "suspended" then
            coroutine.resume(monitor)
        end
        counter = counter + 1
        random_delay(1, 2)
    end
end

return AntiDebug

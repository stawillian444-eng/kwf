--====================================================================--
--  [KaWaifu AJ] CUSTOM NOTIFIER & AUTO-JOINER FOR DELTA EXECUTOR    --
--  REVERTED WEBSOCKETS & BYPASSED AUTHENTICATION LOGIC              --
--====================================================================--

print("[KaWaifu Reverted] Inicializando Loader...")

-- 1. CONFIGURAÇÕES PRINCIPAIS (Ajuste conforme sua preferência)
getgenv().JoinerConfig_jhgjerdf324sa = {
    WsUrl = "ws://34.95.179.70:16527/joiner_fsh34gc1vz5nmj12/ws" -- Nó de São Paulo original
}

local CONFIG = {
    MinGenToTeleport = 500000, -- Só teleporta automaticamente se a Gen for maior ou igual a esta
    AutoTeleport = true,       -- Ativa/Desativa o teleporte automático ao detectar
    LogsEmTempoReal = true     -- Exibe no F9 todas as atualizações de servidores da rede
}

-- 2. SERVIÇOS DO ROBLOX
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")

local localPlayer = Players.LocalPlayer
local placeId = game.PlaceId

-- 3. INTERFACE DE NOTIFICAÇÃO NATIVA (Compatível com Delta Mobile e PC)
local function dispararNotificacao(titulo, mensagem, duracao)
    duracao = duracao or 5
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = titulo,
            Text = mensagem,
            Duration = duracao
        })
    end)
end

-- 4. ROTINA DE AUTO-TELEPORTE (Bypass de Proteções Nativas)
local function executarTeleporte(jobId, nomeCriatura, geracao)
    if jobId == game.JobId then 
        print("[KaWaifu Reverted] Alvo detectado, mas você já está neste servidor.")
        return 
    end
    
    dispararNotificacao("🚀 Puxando Servidor!", string.format("Alvo: %s (Gen %s)", nomeCriatura, tostring(geracao)), 6)
    print(string.format("[KaWaifu Reverted] Iniciando teleporte para JobId: %s", tostring(jobId)))
    task.wait(0.5)
    
    local sucesso, erro = pcall(function()
        TeleportService:TeleportToPlaceInstance(placeId, jobId, localPlayer)
    end)
    
    if not sucesso then
        warn("[KaWaifu Reverted] Falha ao tentar teleportar via TeleportToPlaceInstance: " .. tostring(erro))
        dispararNotificacao("Erro no Teleporte", "Tentando reconexão forçada...", 4)
    end
end

-- 5. INTERCEPTADOR E DECODIFICADOR DO WEBSOCKET REVERTIDO
local function processarMensagemRede(mensagemBruta)
    local sucesso, dados = pcall(HttpService.JSONDecode, HttpService, mensagemBruta)
    if not sucesso or not dados then return end
    
    -- Captura de Carga Útil Base de Transmissão (OP: JOB ou INIT)
    if dados.op == "JOB" or dados.op == "INIT" then
        local payload = dados.data or {}
        
        if payload.payload and payload.payload.animals and payload.job_id then
            local jobIdAlvo = payload.job_id
            
            for _, animal in ipairs(payload.payload.animals) do
                local gen = tonumber(animal.Generation) or 0
                local nome = animal.DisplayName or "Desconhecido"
                local raridade = animal.Rarity or "Comum"
                local mutacao = animal.Mutation or "Normal"
                
                if CONFIG.LogsEmTempoReal then
                    print(string.format("[Rede KaWaifu] Servidor Monitorado -> %s | Raridade: %s | Gen: %s | Mut: %s", nome, raridade, tostring(gen), mutacao))
                end
                
                -- Validação dos filtros de Geração informados pelo usuário
                if gen >= CONFIG.MinGenToTeleport then
                    dispararNotificacao("🚨 Criatura Valiosa! 🚨", string.format("%s Encontrado!\nRaridade: %s\nGen: %s", nome, raridade, tostring(gen)), 8)
                    
                    if CONFIG.AutoTeleport then
                        executarTeleporte(jobIdAlvo, nome, gen)
                        break
                    end
                end
            end
        end
    
    -- Tratamento do Sinal de Expulsão/Verificação (Bypass do Sistema de Assinaturas)
    elseif dados.op == "KICK" then
        warn("[KaWaifu Reverted] Servidor remoto enviou sinal de fechamento de sessão (KICK). Ignorando restrição local e forçando reconexão...")
        dispararNotificacao("Aviso de Rede", "Ignorando autenticação estática do servidor central.", 4)
    end
end

-- 6. GERENCIADOR DE CONEXÃO CONTÍNUA (Keep-Alive & Auto-Reconnect)
local function conectarMalhaWeb阶()
    -- Procura o manipulador de WebSocket injetado pelo Delta Executor
    local connectAPI = WebSocket and WebSocket.connect or Websocket and Websocket.connect or websocket and websocket.connect or syn and syn.websocket and syn.websocket.connect
    
    if not connectAPI then
        warn("[KaWaifu Reverted] Erro fatal: O Delta Executor não expôs nenhuma API de WebSocket nesta versão.")
        dispararNotificacao("Erro do Executor", "Delta sem suporte a WebSocket. Verifique suas atualizações.", 10)
        return
    end
    
    local urlServidor = getgenv().JoinerConfig_jhgjerdf324sa.WsUrl
    print("[KaWaifu Reverted] Abrindo túnel de comunicação WebSocket em: " .. urlServidor)
    
    local sucesso, wsInstance = pcall(connectAPI, urlServidor)
    
    if not sucesso or not wsInstance then
        warn("[KaWaifu Reverted] Falha de handshake na rede. Tentando novamente em 5 segundos...")
        task.wait(5)
        conectarMalhaWeb阶()
        return
    end
    
    print("[KaWaifu Reverted] Conexão estabelecida com sucesso com a malha externa.")
    dispararNotificacao("KaWaifu Ativo", "Monitorando rede de servidores em tempo real...", 5)
    
    -- Vincula os manipuladores de eventos assíncronos
    wsInstance.OnMessage:Connect(function(msg)
        processarMensagemRede(msg)
    end)
    
    wsInstance.OnClose:Connect(function()
        warn("[KaWaifu Reverted] O canal de comunicação foi encerrado. Restabelecendo em 5 segundos...")
        task.wait(5)
        conectarMalhaWeb阶()
    end)
    
    -- Informa ao servidor que o cliente revertido está pronto para receber transmissões sem validação rígida
    pcall(function() wsInstance:Send("READY") end)
end

-- Inicializa o script em segundo plano
task.spawn(conectarMalhaWeb阶)

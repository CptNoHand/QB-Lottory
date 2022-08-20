local QBCore = exports['qb-core']:GetCoreObject()
Lottopayout = 0
Attempts = 1

--Checks the date and time of resource start. Working on handler for automatic draws 

AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
      return
    end
    DrawTimeCheck()
    UpdatePayout(0)

  end)

-- Handles what happens when player uses the lottory ticket
QBCore.Functions.CreateUseableItem("lotto", function(source)
    local source = source
    local item = 'lotto'
    RegisterTicket(source, item)
end)

---- Adds tickets to the lotterytickets table

function RegisterTicket(source, item)
    local player = QBCore.Functions.GetPlayer(source)
    local playerID = player.PlayerData.citizenid
--    local ticket = item
    if Config.Debug then print("lotto system: " .. player.PlayerData.citizenid .. " has submitted a ticket!") end

    if playerID ~= nil then
        MySQL.Async.insert("INSERT INTO lotterytickets (citizenid) VALUES (@citizen) ", {
            ["@citizen"] = playerID
        })
        player.Functions.RemoveItem('lotto', 1)
        TriggerClientEvent('QBCore:Notify', player, Lang:t("lottory.entered"), 'success')
        
        UpdatePayout(Config.TicketValue)
        
    end
end

--- Updates the payout value of the lotteryserver table

function UpdatePayout(value)
    local additional = 0
    if value ~= nil then
        additional = value
    end
    
    MySQL.Async.fetchAll("SELECT * FROM lotteryserver ORDER BY id DESC LIMIT 1", {}, function(result)
    local oldpayout = result[1].Payout
    local newPayout = oldpayout+additional
    Lottopayout = newPayout*Config.Multiplier
    if Config.Debug then print ("payout:", Lottopayout) end

    MySQL.Async.execute("UPDATE lotteryserver SET Payout = ? WHERE id = 1", {
        newPayout
    })
    if Config.AlwaysNotify then ----- if always notify is true, every entry will post to the discord (can be annoying)
    PostToDiscord()
    end

    end)
end

---Sets new pay out value in lottoserver table to 0 then clears all ticket submissions

function ClearPayout()
    local value = 0
    MySQL.Async.execute("UPDATE lotteryserver SET Payout = ? WHERE id = 1", {
        value
    })
    ClearTickets()
end

---- Handles posting VIA webhook to discord (SET WEBHOOKS IN CONFIG)

function PostToDiscord()
    MySQL.Async.fetchAll("SELECT * FROM lotterytickets ORDER BY id DESC LIMIT 1", {}, function(result)
        if result ~= nil then
        local submissions = result[1].id
        local text = (Lang:t("lottory.value", {payout = Lottopayout ,submissions = submissions}))
        PerformHttpRequest(Config.Webhook, function(err, text, header) end, 'POST', json.encode({content = text}), {["Content-Type"] = 'application/json'})
        end
    end)
end

------- Adds Admin Command to force lottery draw

QBCore.Commands.Add(Config.Command, Lang:t("lottory.command"), {}, false, function(source, args)
    TriggerEvent('Lottery:Server:Payout')
end, 'god')

-- Handler for the admin command to trigger early Payout
AddEventHandler("Lottery:Server:Payout", function(src)
    ChooseWinner()
end)


--- Randomly picks an entery from the lotterytickets table than sends the payout funds to the player (currently must be online to recieve)

function ChooseWinner()
    MySQL.Async.fetchAll("SELECT * FROM lotterytickets ORDER BY id DESC LIMIT 1", {}, function(result)
    local totaltickets = result[1].id
    local winningticket = math.random(1, totaltickets)
        MySQL.Async.fetchSingle('SELECT citizenid FROM `lotterytickets` WHERE id = ?', {winningticket}, function(result)
                local characterID = result.citizenid
                
                if characterID ~= nil then
                    
                    MySQL.Async.fetchAll('SELECT * FROM players WHERE citizenid = ? ', {characterID}, function (result)
                        local pData = QBCore.Functions.GetPlayerByCitizenId(characterID)

                        if pData ~= nil then
                        local FirstName = pData.PlayerData.charinfo.firstname
                        local LastName  = pData.PlayerData.charinfo.lastname
                        local Player = QBCore.Functions.GetPlayer(pData.PlayerData.id)
                        
                            if not Player.Offline then
                                MySQL.Async.fetchSingle("SELECT Payout FROM lotteryserver WHERE 1", {}, function(result)
                                local text = (Lang:t("lottory.winner", {payout = Lottopayout, firstname = FirstName, lastname = LastName}))
                                    if Config.Debug then print(text) end
                                    Player.Functions.AddMoney('bank', Lottopayout)
                                    ClearPayout()
                                    PerformHttpRequest(Config.WinHook, function(err, text, header) end, 'POST', json.encode({content = text}), {["Content-Type"] = 'application/json'})
                                    end)
                                
                            
                            
                            end
                        
                        else
                        if Attempts <= Config.Retries then
                                Attempts = Attempts+1
                                if Config.Debug then print('Attempt # '..Attempts..' to find online winner') end
                                Wait(10000)
                                ChooseWinner()
                            else
                                local text = (Lang:t("lottory.failed", {attempts = Config.Retries}))
                                PerformHttpRequest(Config.WinHook, function(err, text, header) end, 'POST', json.encode({content = text}), {["Content-Type"] = 'application/json'})
                                Attempts = 1
                        end    
                            
                        
                        end
                    end)
                end
        end)
    end)
end

--Clears ALL Ticket Submissions

function ClearTickets()
    MySQL.Async.execute("TRUNCATE lotterytickets")
end

-- Checks what time it is and waits patiently for the draw
function DrawTimeCheck()
    local t = os.date("*t")
        if Config.Debug then
            print('Checking Time '..'Day:'..t.wday..' Hour: '..t.hour..' Min:'..t.min)
        end
    if t.wday == Config.DrawDay and t.hour == Config.DrawTime and t.min == 0 then
                    ChooseWinner()
    end
    Wait(60000) -- Check every minute
    DrawTimeCheck()    
end
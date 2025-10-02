local triggered = false

AddEventHandler('playerSpawned', function()
    if not triggered then
        triggered = true
        Citizen.Wait(20000) -- Wait 20 seconds
        TriggerServerEvent('ne_discord:PlayerLoaded')
    end
end)
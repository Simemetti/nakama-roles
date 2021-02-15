local nk = require("nakama")

local ready_op_code = -1

local roles = {
    dps = 2,
    heal = 2,
    tank = 2
}

local function find_roles(context, payload)
    local json = nk.json_decode(payload)

    local query = "+label." .. json.role .. ":>0"

    local matches = nk.match_list(1, true, nil, 0, 2, query)

    if #matches > 0 then
        return matches[1].match_id
    else
        local match_id = nk.match_create("roles", { label = nk.json_encode(roles) })
        return match_id
    end

    return nk.json_encode(json)
end

nk.register_rpc(find_roles, "find_roles")

local M = {}

function M.match_init(context, setupstate)
    local gamestate = {}
    gamestate.max_size = 0

    for role,num_role in pairs(roles) do
        gamestate.max_size = gamestate.max_size + num_role
    end
    gamestate.size = 0
    gamestate.presences = {}

    local tickrate = 10
    local label = setupstate.label
    return gamestate, tickrate, label
end

function M.match_join_attempt(context, dispatcher, tick, state, presence, metadata)
    local acceptuser = true
    local table_label = nk.json_decode(context.match_label)
    table_label[metadata.role] = table_label[metadata.role] - 1
    dispatcher.match_label_update(nk.json_encode(table_label))
    return state, acceptuser
end

function M.match_join(context, dispatcher, tick, state, presences)
    state.size = state.size + 1

    for _, p in pairs(presences) do
        table.insert(state.presences,p)
    end

    nk.logger_info(state.max_size)

    if state.size == state.max_size then
        dispatcher.broadcast_message(ready_op_code)
    end

    return state
end

function M.match_leave(context, dispatcher, tick, state, presences)
    state.size = state.size - 1

    if state.size == 0 then 
        return nil
    end

    return state
end

function M.match_loop(context, dispatcher, tick, state, messages)
    for _,message in pairs(messages) do
        local recievers = {}

        for _, p in pairs(state.presences) do
            if message.sender.user_id ~= p.user_id then
                table.insert(recievers, p)
            end
        end

        dispatcher.broadcast_message(message.op_code, message.data, recievers)
    end

    return state
end

function M.match_terminate(context, dispatcher, tick, state, grace_seconds)
    return state
end

return M
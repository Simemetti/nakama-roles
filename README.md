# nakama-roles

A modules to add role selection when searching for matches on nakama

## Installation

Copy the file role.lua in the modules folder of your nakama installation

## Usage

The way this system works is by making players wait in a match until every role is filled with the desired numbers of players, meanwhile the label of the match gets continously update to advertise which roles are still open to join.

When a player has selected their role and is ready to join a match you need to call the `find_roles` RPC with your client, passing a dictionary with the format `{"roles":role}`.
This will always return a match_id that the player can join because if no suitable game is found one will be created. Here's an example with my client using Godot:
```GDScript
var match_id = yield(Multy.client.rpc_async(
		Multy.session,"find_roles",JSON.print({"role":Multy.role})),
	"completed")
```

With the match_id the client can now join a match. You need to send another `{"roles":role}` dictionary as metadata:
```GDScript
Multy.joined_match = yield(Multy.socket.join_match_async(
		result.payload,{"role":Multy.role}),
	"completed")
```

Note that the joined match loop will start upon the first player's connection, AKA as soon as now clients are able to send messages to each other but since there's no garanteed that the match has been filled with players any gameplay that require every player to be connected must wait. 

When every role is full the server will send an empty message to clients with the `ready_op_code` as op_code. You can configure what this op_code should be for you at the top of the roles.lua file along with how many and which roles you need for your game. 

```lua
local ready_op_code = -1


local roles = {
    dps = 2,
    heal = 2,
    tank = 2
}
```

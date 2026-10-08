#import "Basic";
#import "String";
#import "Math";
Communication :: #import "Communication";

#scope_export

// Frozen end-level data, without references to a live scene or networking.
Player_Result :: struct {
	player_id: int;
	participant_id: int = -1;
	display_name: string;
	icon_id: int;
	death_count: int;
	revive_count: int;
	win_count: int;
	score: int;
	// Unscaled recursive score, before integer rounding.
	dividend: float64;
	picked_trophy: bool;
}

Record :: struct {
	status: enum { Loading; Missing; Available; } = .Loading;
	time_ms: int;
	holder: string;
}

Result :: struct {
	round_id: int;
	level_id: int = -1;
	level_name: string;
	next_level_name: string;
	duration_ms: int;
	winner_id: int = -1;
	most_death_id: int = -1;
	most_revive_id: int = -1;
	players: [] Player_Result;
	// Stable roster order. [a * players.count + b] counts revives by a of b.
	// Empty means unavailable, not an all-zero matrix.
	revives: [] int;
	ranked_player_ids: [] int;
	has_player_statistics := false;
	record: Record;
	personal_share_weight: float64 = 1;
	client: struct {
		// Derived animation data; never part of a protocol message.
		share_denominators: [] float64;
		direct_scores: [] float64;
		// [recipient * roster size + source]: exact second-round contributions.
		secondary_transfers: [] float64;
	}
}

Presentation :: struct {
	// Seconds since the panel opened; independent of run time and countdown.
	clock: float64;
	countdown_remaining: float64;
}

find_player :: (result: Result, player_id: int) -> *Player_Result {
	for * result.players if it.player_id == player_id return it;
	return null;
}

// Stored results own their arrays and strings, so a scene reset is harmless.
clear_result :: (result: *Result, allocator := context.allocator) {
	push_allocator(allocator);
	free(result.level_name);
	free(result.next_level_name);
	free(result.record.holder);
	for result.players free(it.display_name);
	free(result.players.data);
	free(result.revives.data);
	free(result.ranked_player_ids.data);
	free(result.client.share_denominators.data);
	free(result.client.direct_scores.data);
	free(result.client.secondary_transfers.data);
	result.* = .{};
}

copy_result :: (source: Result, result: *Result, allocator := context.allocator) {
	push_allocator(allocator);
	clear_result(result, allocator);
	result.* = source;
	result.level_name = copy_string(source.level_name);
	result.next_level_name = copy_string(source.next_level_name);
	result.record.holder = copy_string(source.record.holder);
	result.players = NewArray(source.players.count, Player_Result);
	for source.players {
		result.players[it_index] = it;
		result.players[it_index].display_name = copy_string(it.display_name);
	}
	result.revives = NewArray(source.revives.count, int);
	for source.revives result.revives[it_index] = it;
	result.ranked_player_ids = NewArray(source.ranked_player_ids.count, int);
	for source.ranked_player_ids result.ranked_player_ids[it_index] = it;
	result.client.share_denominators = NewArray(source.client.share_denominators.count, float64);
	for source.client.share_denominators result.client.share_denominators[it_index] = it;
	result.client.direct_scores = NewArray(source.client.direct_scores.count, float64);
	for source.client.direct_scores result.client.direct_scores[it_index] = it;
	result.client.secondary_transfers = NewArray(source.client.secondary_transfers.count, float64);
	for source.client.secondary_transfers result.client.secondary_transfers[it_index] = it;
}

Participant :: struct {
	id: int;
	profile_id: int = -1;
	player_id: int = -1; // Current connection's gameplay id; not the session identity.
	display_name: string;
	icon_id: int;
	active: bool;
	death_count: int;
	revive_count: int;
	win_count: int;
	score: int; // Sum of settled, completed levels.
	server: struct {
		// Keep old connection ids until the session ends, including disconnects
		// during a run. Frozen results can still settle to the same participant.
		player_ids: [..] int;
	}
}

Revive_Pair :: struct {
	reviver_id: int;
	revived_id: int;
	count: int;
}

// One attempt per scene. A wipe changes run_generation and clears only this
// ledger; disconnected participants and completed session results survive.
Level_Attempt :: struct {
	scene_id: int;
	run_generation: int;
	level_players: [..] Player_Result;
	level_revives: [..] Revive_Pair;
	completed_round_id: int;
}

// Ownership/lifetime contract:
// - Server: exactly one live Play_Session per Instance.
// - Client: exactly one live Play_Session in State, including outside an Instance.
// - Only a requested server snapshot changes the client's session.
// - Its allocator is captured at init and used for every owned allocation/free.
// Instance routes simulation facts here; Scene owns no scoring ledger.
Play_Session :: struct {
	allocator: Allocator;
	initialized: bool;
	instance_id: int = -1;
	id: int = -1; // Identity is (instance_id, id); id changes for a scheduled session.
	revision: int;
	participants: [..] Participant;
	completed_levels: [..] Result;

	server: struct {
		next_participant_id := 1;
		next_round_id := 1;
		levels: [..] Level_Attempt;
	}
	client: struct {
		request_id: int;
		sync_pending: bool;
		// Announcements don't replace the live session; they only trigger a request.
		expected_instance_id: int = -1;
		expected_session_id: int = -1;
		expected_revision: int;
		// Announcement only: the result itself still arrives through session sync.
		end_level_round_id: int;
	}
}

init :: (session: *Play_Session, allocator: Allocator, instance_id := -1, id := -1) {
	assert(!session.initialized);
	session.* = .{};
	session.allocator = allocator;
	session.initialized = true;
	session.instance_id = instance_id;
	session.id = id;
	session.participants.allocator = allocator;
	session.completed_levels.allocator = allocator;
	session.server.levels.allocator = allocator;
}

clear :: (session: *Play_Session) {
	assert(session.initialized);
	push_allocator(session.allocator);
	for session.participants {
		free(it.display_name);
		array_free(it.server.player_ids);
	}
	for *session.completed_levels clear_result(it, session.allocator);
	array_reset(*session.participants);
	array_reset(*session.completed_levels);
	for session.server.levels {
		array_free(it.level_players);
		array_free(it.level_revives);
	}
	array_free(session.server.levels);
	session.instance_id = -1;
	session.id = -1;
	session.revision = 0;
	session.server = .{};
	session.server.levels.allocator = session.allocator;
}

free :: (session: *Play_Session) {
	if !session.initialized return;
	clear(session);
	array_free(session.participants);
	array_free(session.completed_levels);
	session.* = .{};
}

find_participant :: (session: *Play_Session, id: int) -> *Participant {
	for *session.participants if it.id == id return it;
	return null;
}

find_participant_by_player :: (session: *Play_Session, player_id: int) -> *Participant {
	for *session.participants {
		if it.player_id == player_id return it;
		for old_id: it.server.player_ids if old_id == player_id return it;
	}
	return null;
}

join :: (session: *Play_Session, player_id: int, profile_id: int, display_name: string) -> int {
	push_allocator(session.allocator);
	participant: *Participant;
	if profile_id >= 0 {
		for *session.participants if it.profile_id == profile_id { participant = it; break; }
	}
	if !participant {
		array_add(*session.participants, .{ id = session.server.next_participant_id, profile_id = profile_id });
		session.server.next_participant_id += 1;
		participant = *session.participants[session.participants.count-1];
		participant.server.player_ids.allocator = session.allocator;
	}
	array_add(*participant.server.player_ids, player_id);
	participant.player_id = player_id;
	participant.active = true;
	free(participant.display_name);
	participant.display_name = copy_string(display_name);
	session.revision += 1;
	return participant.id;
}

leave :: (session: *Play_Session, participant_id: int) {
	participant := find_participant(session, participant_id);
	if participant {
		participant.active = false;
		session.revision += 1;
	}
}

latest_result :: (session: *Play_Session) -> *Result {
	if !session.completed_levels.count return null;
	return *session.completed_levels[session.completed_levels.count-1];
}

find_result :: (session: *Play_Session, round_id: int) -> *Result {
	for *session.completed_levels if it.round_id == round_id return it;
	return null;
}

find_level :: (session: *Play_Session, scene_id: int, run_generation: int) -> *Level_Attempt {
	for *session.server.levels
		if it.scene_id == scene_id && it.run_generation == run_generation return it;
	return null;
}

ensure_level :: (session: *Play_Session, scene_id: int, run_generation: int) -> *Level_Attempt {
	for *session.server.levels if it.scene_id == scene_id {
		if it.run_generation != run_generation {
			array_reset(*it.level_players);
			array_reset(*it.level_revives);
			it.run_generation = run_generation;
			it.completed_round_id = 0;
		}
		return it;
	}
	array_add(*session.server.levels, .{ scene_id = scene_id, run_generation = run_generation });
	level := *session.server.levels[session.server.levels.count-1];
	level.level_players.allocator = session.allocator;
	level.level_revives.allocator = session.allocator;
	return level;
}

find_level_player :: (session: *Play_Session, level: *Level_Attempt, player_id: int) -> *Player_Result {
	participant := find_participant_by_player(session, player_id);
	for *level.level_players {
		if it.player_id == player_id return it;
		if participant && it.participant_id == participant.id return it;
	}
	return null;
}

register_level_player :: (session: *Play_Session, level: *Level_Attempt, player_id: int, icon_id: int) {
	if level.completed_round_id || icon_id <= 0 return;
	player := find_level_player(session, level, player_id);
	if player {
		player.icon_id = icon_id;
		return;
	}
	participant := find_participant_by_player(session, player_id);
	participant_id := ifx participant then participant.id else -1;
	array_add(*level.level_players, .{ player_id = player_id, participant_id = participant_id, icon_id = icon_id });
}

record_level_trophy :: (session: *Play_Session, level: *Level_Attempt, player_id: int) {
	if level.completed_round_id return;
	player := find_level_player(session, level, player_id);
	if player player.picked_trophy = true;
}

record_level_death :: (session: *Play_Session, level: *Level_Attempt, player_id: int) {
	if level.completed_round_id return;
	player := find_level_player(session, level, player_id);
	if player player.death_count += 1;
}

record_level_revive :: (session: *Play_Session, level: *Level_Attempt, reviver_id: int, revived_id: int) {
	if level.completed_round_id return;
	reviver := find_level_player(session, level, reviver_id);
	revived := find_level_player(session, level, revived_id);
	if !reviver || !revived || reviver == revived return;
	reviver.revive_count += 1;
	for *level.level_revives if it.reviver_id == reviver.player_id && it.revived_id == revived.player_id {
		it.count += 1;
		return;
	}
	array_add(*level.level_revives, .{ reviver.player_id, revived.player_id, 1 });
}

complete_level :: (session: *Play_Session, level: *Level_Attempt, level_id: int,
	level_name: string, next_level_name: string, winner_id: int, duration_ms: int,
	personal_share_weight: float64) -> *Result {
	if level.completed_round_id return find_result(session, level.completed_round_id);
	// Assemble scratch input without borrowing any Scene allocation. commit_level
	// freezes an owned result using the session's captured allocator.
	result: Result;
	result.level_id = level_id;
	result.level_name = level_name;
	result.next_level_name = next_level_name;
	winner := find_level_player(session, level, winner_id);
	result.winner_id = ifx winner then winner.player_id else winner_id;
	result.duration_ms = duration_ms;
	result.personal_share_weight = personal_share_weight;
	result.has_player_statistics = true;
	n := level.level_players.count;
	result.players = NewArray(n, Player_Result,, temp);
	result.revives = NewArray(n*n, int,, temp);
	for level.level_players {
		result.players[it_index] = it;
		if it.player_id == result.winner_id result.players[it_index].win_count = 1;
		deaths := find_player(result, result.most_death_id);
		revives := find_player(result, result.most_revive_id);
		if !deaths || it.death_count > deaths.death_count result.most_death_id = it.player_id;
		if !revives || it.revive_count > revives.revive_count result.most_revive_id = it.player_id;
	}
	for level.level_revives {
		i := -1; j := -1;
		for player: result.players {
			if player.player_id == it.reviver_id i = it_index;
			if player.player_id == it.revived_id j = it_index;
		}
		if i >= 0 && j >= 0 result.revives[i*n+j] = it.count;
	}
	calculate(*result, temp);
	settled := commit_level(session, result);
	level.completed_round_id = settled.round_id;
	return settled;
}

// Called exactly once by Instance when a Scene completes a run. No persistent
// pointers into the Scene, a packet, or temporary storage are retained.
commit_level :: (session: *Play_Session, source: Result) -> *Result {
	owned: Result;
	copy_result(source, *owned, session.allocator);
	owned.round_id = session.server.next_round_id;
	session.server.next_round_id += 1;
	push_allocator(session.allocator);
	for *owned.players {
		participant := find_participant(session, it.participant_id);
		if !participant participant = find_participant_by_player(session, it.player_id);
		if !participant continue;
		it.participant_id = participant.id;
		free(it.display_name);
		it.display_name = copy_string(participant.display_name);
		participant.icon_id = it.icon_id;
		participant.score += it.score;
	}
	array_add(*session.completed_levels, owned);
	session.revision += 1;
	return latest_result(session);
}

// Protocol types are owned by Communication, deliberately duplicated. These
// conversions are the only boundary: neither side serializes gameplay structs.
make_result_message :: (result: Result, allocator := temp) -> Communication.Command.Level_Result {
	push_allocator(allocator);
	message: Communication.Command.Level_Result;
	message.round_id = result.round_id;
	message.level_id = result.level_id;
	message.level_name = copy_string(result.level_name);
	message.next_level_name = copy_string(result.next_level_name);
	message.duration_ms = result.duration_ms;
	message.winner_id = result.winner_id;
	message.most_death_id = result.most_death_id;
	message.most_revive_id = result.most_revive_id;
	message.has_player_statistics = result.has_player_statistics;
	message.personal_share_weight = result.personal_share_weight;
	message.record.status = xx result.record.status;
	message.record.time_ms = result.record.time_ms;
	message.record.holder = copy_string(result.record.holder);
	message.players = NewArray(result.players.count, Communication.Command.Player_Result);
	for result.players {
		message.players[it_index] = .{
			player_id = it.player_id, participant_id = it.participant_id,
			display_name = copy_string(it.display_name), icon_id = it.icon_id,
			death_count = it.death_count, revive_count = it.revive_count,
			win_count = it.win_count, score = it.score, dividend = it.dividend, picked_trophy = it.picked_trophy
		};
	}
	message.revives = NewArray(result.revives.count, int);
	for result.revives message.revives[it_index] = it;
	message.ranked_player_ids = NewArray(result.ranked_player_ids.count, int);
	for result.ranked_player_ids message.ranked_player_ids[it_index] = it;
	return message;
}

read_result_message :: (message: Communication.Command.Level_Result, result: *Result, allocator: Allocator) {
	// Borrow packet data only until copy_result has taken ownership.
	source: Result;
	source.round_id = message.round_id;
	source.level_id = message.level_id;
	source.level_name = message.level_name;
	source.next_level_name = message.next_level_name;
	source.duration_ms = message.duration_ms;
	source.winner_id = message.winner_id;
	source.most_death_id = message.most_death_id;
	source.most_revive_id = message.most_revive_id;
	source.has_player_statistics = message.has_player_statistics;
	source.personal_share_weight = message.personal_share_weight;
	source.record = .{ status = xx message.record.status, time_ms = message.record.time_ms, holder = message.record.holder };
	source.players = NewArray(message.players.count, Player_Result,, temp);
	for message.players {
		source.players[it_index] = .{
			player_id = it.player_id, participant_id = it.participant_id,
			display_name = it.display_name, icon_id = it.icon_id,
			death_count = it.death_count, revive_count = it.revive_count,
			win_count = it.win_count, score = it.score, dividend = it.dividend, picked_trophy = it.picked_trophy
		};
	}
	source.revives = message.revives;
	source.ranked_player_ids = message.ranked_player_ids;
	copy_result(source, result, allocator);
	prepare_presentation(result, allocator);
}

make_sync_message :: (session: *Play_Session, request_id: int) -> Communication.Command.Ans_Play_Session {
	push_allocator(temp);
	message: Communication.Command.Ans_Play_Session;
	message.request_id = request_id;
	message.instance_id = session.instance_id;
	message.session_id = session.id;
	message.revision = session.revision;
	message.status = .Available;
	message.participants = NewArray(session.participants.count, Communication.Command.Session_Participant);
	for session.participants {
		message.participants[it_index] = .{
			id = it.id, profile_id = it.profile_id, player_id = it.player_id,
			display_name = copy_string(it.display_name), icon_id = it.icon_id, active = it.active,
			death_count = it.death_count, revive_count = it.revive_count,
			win_count = it.win_count, score = it.score
		};
	}
	message.completed_levels = NewArray(session.completed_levels.count, Communication.Command.Level_Result);
	for session.completed_levels message.completed_levels[it_index] = make_result_message(it);
	return message;
}

begin_sync :: (session: *Play_Session) -> Communication.Command.Ask_Play_Session {
	session.client.request_id += 1;
	session.client.sync_pending = true;
	return .{ request_id = session.client.request_id };
}

apply_sync :: (session: *Play_Session, message: Communication.Command.Ans_Play_Session) -> bool {
	if !session.client.sync_pending || message.request_id != session.client.request_id return false;
	if message.status != .Available && message.status != .No_Instance return false;
	if message.status == .Available {
		// Reject stale announcements/snapshots without replacing owned data.
		if message.instance_id != session.client.expected_instance_id && session.client.expected_instance_id >= 0 return false;
		if message.session_id != session.client.expected_session_id && session.client.expected_session_id >= 0 return false;
		if message.revision < session.client.expected_revision return false;
		for message.completed_levels {
			n := it.players.count;
			if n > 1024 || it.revives.count != n*n || !(it.personal_share_weight > 0) return false;
			for i: 0..n-1 {
				if it.revives[i*n+i] != 0 return false;
			}
			for count: it.revives if count < 0 return false;
		}
	}
	clear(session);
	session.instance_id = message.instance_id;
	session.id = message.session_id;
	session.revision = message.revision;
	if message.status == .Available {
		push_allocator(session.allocator);
		for message.participants {
			array_add(*session.participants, .{
				id = it.id, profile_id = it.profile_id, player_id = it.player_id,
				display_name = copy_string(it.display_name), icon_id = it.icon_id, active = it.active,
				death_count = it.death_count, revive_count = it.revive_count,
				win_count = it.win_count, score = it.score
			});
		}
		for message.completed_levels {
			result: Result;
			read_result_message(it, *result, session.allocator);
			array_add(*session.completed_levels, result);
		}
	}
	session.client.sync_pending = false;
	session.client.expected_instance_id = session.instance_id;
	session.client.expected_session_id = session.id;
	session.client.expected_revision = session.revision;
	return true;
}

WINNER_REWARD :: 1000;
TROPHY_REWARD :: 900;

base_reward :: (result: Result, index: int) -> float64 {
	player := result.players[index];
	if player.player_id == result.winner_id return WINNER_REWARD;
	if player.picked_trophy return TROPHY_REWARD;
	return 0;
}
// k in diag(total revives) + k I - R. Must stay strictly positive.
PERSONAL_SHARE_WEIGHT :: 1.0;
SETTLEMENT_ROUNDS :: 2;
INITIAL_HOLD_SECONDS :: 0.35;
DIRECT_SECONDS :: 1.8;
INTERMEDIATE_HOLD_SECONDS :: 0.5;
RECURSIVE_SECONDS :: 2.6;
RECURSIVE_START :: INITIAL_HOLD_SECONDS + DIRECT_SECONDS + INTERMEDIATE_HOLD_SECONDS;
SETTLEMENT_SECONDS :: RECURSIVE_START + RECURSIVE_SECONDS;

calculate :: (result: *Result, allocator := context.allocator) {
	n := result.players.count;
	assert(result.personal_share_weight > 0, "Personal share weight must be positive");
	assert(result.revives.count == n * n, "Revive matrix must match the roster");
	k := result.personal_share_weight;
	result.client.share_denominators = NewArray(n, float64,, allocator);
	result.ranked_player_ids = NewArray(n, int,, allocator);
	result.client.direct_scores = NewArray(n, float64,, allocator);
	result.client.secondary_transfers = NewArray(n*n, float64,, allocator);
	winner := -1;
	for *player: result.players {
		player.score = 0;
		player.dividend = 0;
		result.ranked_player_ids[it_index] = player.player_id;
		if player.player_id == result.winner_id winner = it_index;
	}
	if winner < 0 return;

	// S[i,j] = R[i,j] / (k + column_sum(R)[j]). Solve (I - S) x = b
	// via (diag(k + column_sum(R)) - R) y = b, where x[j] = denominator[j]*y[j].
	// Every column sum of S is < 1 for k > 0, so the solution is unique.
	matrix := NewArray(n * n, float64,, temp);
	rhs := NewArray(n, float64,, temp);
	for j: 0..n-1 {
		assert(result.revives[j*n+j] == 0, "A player cannot revive themself");
		denominator := k;
		for i: 0..n-1 {
			count := result.revives[i * n + j];
			assert(count >= 0);
			denominator += count.(float64);
			matrix[i * n + j] = -count.(float64);
		}
		result.client.share_denominators[j] = denominator;
		matrix[j * n + j] += denominator;
	}
	for i: 0..n-1 rhs[i] = base_reward(result.*, i);
	for column: 0..n-1 {
		pivot := column;
		for row: column+1..n-1 {
			if abs(matrix[row*n+column]) > abs(matrix[pivot*n+column]) pivot = row;
		}
		assert(abs(matrix[pivot*n+column]) > 0);
		if pivot != column {
			for j: column..n-1 {
				swap := matrix[column*n+j];
				matrix[column*n+j] = matrix[pivot*n+j];
				matrix[pivot*n+j] = swap;
			}
			swap := rhs[column]; rhs[column] = rhs[pivot]; rhs[pivot] = swap;
		}
		for row: column+1..n-1 {
			factor := matrix[row*n+column] / matrix[column*n+column];
			for j: column+1..n-1 matrix[row*n+j] -= factor * matrix[column*n+j];
			rhs[row] -= factor * rhs[column];
		}
	}
	for reverse: 0..n-1 {
		i := n - 1 - reverse;
		for j: i+1..n-1 rhs[i] -= matrix[i*n+j] * rhs[j];
		rhs[i] /= matrix[i*n+i];
		rhs[i] = max(cast(float64) 0, rhs[i]);
	}
	// Keep the natural solution x = b + S*x, including all trophy awards.
	// Returning shares can increase any final score above its base award.
	for *player: result.players {
		player.dividend = result.client.share_denominators[it_index] * rhs[it_index];
		player.score = floor(player.dividend).(int);
	}
	prepare_presentation(result, allocator, allocate = false);
	// Level winner first, then actual dividends (not rounded score ties).
	// Equal dividends retain roster order.
	for i: 1..n-1 {
		j := i;
		while j > 0 {
			a := find_player(result.*, result.ranked_player_ids[j-1]);
			b := find_player(result.*, result.ranked_player_ids[j]);
			if a.player_id == result.winner_id break;
			if b.player_id != result.winner_id && a.dividend >= b.dividend break;
			swap := result.ranked_player_ids[j-1];
			result.ranked_player_ids[j-1] = result.ranked_player_ids[j];
			result.ranked_player_ids[j] = swap;
			j -= 1;
		}
	}
}

smooth :: (t: float64) -> float64 {
	x := clamp(t, 0.0, 1.0);
	return x*x*(3 - 2*x);
}

displayed_score :: (result: Result, index: int, clock: float64) -> int {
	player := result.players[index];
	if clock >= SETTLEMENT_SECONDS return player.score;
	base := base_reward(result, index);
	if result.client.direct_scores.count != result.players.count return base.(int);
	amount := base + (result.client.direct_scores[index] - base) * smooth((clock - INITIAL_HOLD_SECONDS) / DIRECT_SECONDS);
	if clock >= RECURSIVE_START amount += (player.dividend - result.client.direct_scores[index]) * smooth((clock - RECURSIVE_START) / RECURSIVE_SECONDS);
	return min(player.score, max(0, floor(amount).(int)));
}

prepare_presentation :: (result: *Result, allocator := context.allocator, allocate := true) {
	n := result.players.count;
	if allocate {
		result.client.share_denominators = NewArray(n, float64,, allocator);
		result.client.direct_scores = NewArray(n, float64,, allocator);
		result.client.secondary_transfers = NewArray(n*n, float64,, allocator);
	}
	winner := -1;
	for result.players if it.player_id == result.winner_id winner = it_index;
	for j: 0..n-1 {
		denominator := result.personal_share_weight;
		for i: 0..n-1 denominator += result.revives[i*n+j];
		result.client.share_denominators[j] = denominator;
	}
	if winner < 0 return;
	for i: 0..n-1 {
		result.client.direct_scores[i] = base_reward(result.*, i);
		for j: 0..n-1
			result.client.direct_scores[i] += base_reward(result.*, j) * result.revives[i*n+j].(float64) / result.client.share_denominators[j];
	}
	// First round: d = b + S*b.
	// Second round: x - d = S*(x - b), since x = b + S*x.
	// Every trophy picker is a source of direct and returning shares.
	for i: 0..n-1 for j: 0..n-1 {
		if i == j continue;
		remaining := result.players[j].dividend - base_reward(result.*, j);
		result.client.secondary_transfers[i*n+j] = result.revives[i*n+j].(float64) * remaining / result.client.share_denominators[j];
	}

}


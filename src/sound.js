let audio_id_to_buffer = {};
let audio_id_counter = 0;

let sound_id_to_sound = {};
let sound_id_counter = 0;

let sound_id_to_state = {};
const SOUND_PLAYING = 1;
const SOUND_STOPPED = 2;

const blobToAudioBuffer = async (blob) => {
	const buffer = await blob.arrayBuffer();
	return await audio_context.decodeAudioData(buffer);
}

jai_imports.js_load_audio = (params_ptr) => {
	const data = getU64(params_ptr, 0);
	const size = getU64(params_ptr, 8);
	const id_ptr = getU64(params_ptr, 16);
	const compressed = getU64(params_ptr, 24) != 0;

	switch (wasm_pause()) {
		case 0: (async () => {
			const array = new Uint8Array(jai_exports.memory.buffer, Number(data), Number(size));
			const buffer = await blobToAudioBuffer(new Blob([array]));

			audio_id_counter += 1;
			const audio_id = audio_id_counter;
			audio_id_to_buffer[audio_id] = buffer;

			setU64(id_ptr, 0, audio_id);
			return +1;
		})().then(wasm_resume); break;
	}
}

jai_imports.js_play_audio = (params_ptr) => {
	const id = getU64(params_ptr, 0);
	const x = getF32(params_ptr, 8);
	const y = getF32(params_ptr, 12);
	const z = getF32(params_ptr, 16);
	const volume = getF32(params_ptr, 20);
	const pitch = getF32(params_ptr, 24);
	let loop = getU32(params_ptr, 28) != 0;
	const kind = getS32(params_ptr, 32);
	const fade_in = getS32(params_ptr, 36);
	const sound_id_ptr = getU64(params_ptr, 40);

	const buffer = audio_id_to_buffer[id];
	if (!buffer) {
		console.error(`Audio buffer with id ${id} not found`);
		setU64(sound_id_ptr, 0, 0);
		return;
	}

	const source = audio_context.createBufferSource();
	source.buffer = buffer;
	source.loop = loop;
	// source.playbackRate.value = pitch;
	
	const gainNode = audio_context.createGain();
	gainNode.gain.setValueAtTime(0, audio_context.currentTime);
	gainNode.gain.linearRampToValueAtTime(volume, audio_context.currentTime + fade_in / 1000);
	
	let panner = null;
	if (kind == 0) {
		panner = audio_context.createPanner();
		panner.panningModel = 'equalpower';
		panner.distanceModel = 'exponential';
		panner.refDistance = 1.0;
		panner.maxDistance = 1000;
		panner.rolloffFactor = 3.0;
		panner.setPosition(x, y, z);
		
		source.connect(gainNode);
		gainNode.connect(panner);
		panner.connect(audio_context.destination);
	} else {
		// no spatialization
		source.connect(gainNode);
		gainNode.connect(audio_context.destination);
	}
	
	source.start(0);
	
	sound_id_counter += 1;
	const sound_id = sound_id_counter;
	sound_id_to_sound[sound_id] = {
		source,
		gainNode,
		panner,
		audio_id: id,
	};
	sound_id_to_state[sound_id] = SOUND_PLAYING;
	
	source.onended = () => {
		delete sound_id_to_sound[sound_id];
		sound_id_to_state[sound_id] = SOUND_STOPPED;
	};

	setU64(sound_id_ptr, 0, sound_id);
}

jai_imports.js_query_sound = (params_ptr) => {
	const sound_idx = getU64(params_ptr, 0);
	const audio_id_ptr = getU64(params_ptr, 8);
	const x_ptr = getU64(params_ptr, 16);
	const y_ptr = getU64(params_ptr, 24);
	const z_ptr = getU64(params_ptr, 32);
	const volume_ptr = getU64(params_ptr, 40);
	const pitch_ptr = getU64(params_ptr, 48);
	const playing_ptr = getU64(params_ptr, 56);
	const looping_ptr = getU64(params_ptr, 64);

	const sound = sound_id_to_sound[sound_idx];
	if (!sound) {
		setU64(audio_id_ptr, 0, 0);
		setF32(x_ptr, 0, 0);
		setF32(y_ptr, 0, 0);
		setF32(z_ptr, 0, 0);
		setF32(volume_ptr, 0, 0);
		setF32(pitch_ptr, 0, 0);
		setU32(playing_ptr, 0, 0);
		setU32(looping_ptr, 0, 0);
		return;
	}

	let source = sound.source;
	let gainNode = sound.gainNode;
	let panner = sound.panner;
	const audio_id = sound.audio_id;

	const pos = [0, 0, 0];
	if (panner) {
		pos[0] = panner.positionX.value;
		pos[1] = panner.positionY.value;
		pos[2] = panner.positionZ.value;
	}
	const volume = gainNode.gain.value;
	const rate = source.playbackRate.value;
	const playing = sound_id_to_state[sound_id] === SOUND_PLAYING ? 1 : 0;
	const looping = source.loop ? 1 : 0;

	setU64(audio_id_ptr, 0, audio_id);
	setF32(x_ptr, 0, pos[0]);
	setF32(y_ptr, 0, pos[1]);
	setF32(z_ptr, 0, pos[2]);
	setF32(volume_ptr, 0, volume);
	setF32(pitch_ptr, 0, rate);
	setU32(playing_ptr, 0, playing);
	setU32(looping_ptr, 0, looping);
}

jai_imports.js_set_sound = (params_ptr) => {
	const sound_idx = getU64(params_ptr, 0);
	const x = getF32(params_ptr, 8);
	const y = getF32(params_ptr, 12);
	const z = getF32(params_ptr, 16);
	const volume = getF32(params_ptr, 20);
	const pitch = getF32(params_ptr, 24);
	const playing = getU32(params_ptr, 28);
	const looping = getU32(params_ptr, 32);

	const sound = sound_id_to_sound[sound_idx];
	if (!sound) {
		return;
	}

	let source = sound.source;
	let gainNode = sound.gainNode;
	let panner = sound.panner;
	
	if (panner) {
		panner.positionX.value = x;
		panner.positionY.value = y;
		panner.positionZ.value = z;
	}
	gainNode.gain.value = volume;
	// source.playbackRate.value = pitch;

	const is_sound_playing = sound_id_to_state[sound_idx] === SOUND_PLAYING;
	if (playing) {
		if (!is_sound_playing) {
			source.start(0);
			sound_id_to_state[sound_idx] = SOUND_PLAYING;
		}
	} else {
		if (is_sound_playing) {
			source.stop(0);
			sound_id_to_state[sound_idx] = SOUND_STOPPED;
		}
	}
	source.loop = looping != 0;

}

jai_imports.js_set_listener_info = (params_ptr) => {
	const x = getF32(params_ptr, 0);
	const y = getF32(params_ptr, 4);
	const z = getF32(params_ptr, 8);
	const forward_x = getF32(params_ptr, 12);
	const forward_y = getF32(params_ptr, 16);
	const forward_z = getF32(params_ptr, 20);

	audio_context.listener.positionX.value = x;
	audio_context.listener.positionY.value = y;
	audio_context.listener.positionZ.value = z;
	audio_context.listener.forwardX.value = forward_x;
	audio_context.listener.forwardY.value = forward_y;
	audio_context.listener.forwardZ.value = forward_z;
	audio_context.listener.upX.value = 0;
	audio_context.listener.upY.value = 0;
	audio_context.listener.upZ.value = 1;
}

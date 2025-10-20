Scene :: #import "Scene";
#import "Basic";


#scope_export

Person :: struct {
	person_id: int;
	score: Scene.Score;
}

Instance :: struct {
	playing_scene_id: int;
	persons: [..] Person;
}

free :: (instance: Instance) {
	array_free(*instance.persons);
}

find_person_by_id :: (instance: Instance, person_id: int) -> *Person {
	for * instance.persons {
		if it.person_id == person_id {
			return it;
		}
	}
	return null;
}
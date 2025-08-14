#import "Basic";

#scope_export


Period :: struct(period: float) {
	last: Apollo_Time;
}
Counter :: struct(n: int) {
	count := 0;
}
check :: (counter: *Counter) -> bool {
	counter.count += 1;
	if counter.count > counter.n {
		counter.count = 0;
		return true;
	}
	return false;
}

check :: (period: *Period) -> bool, float {
	t := current_time_monotonic();
	dt := to_float64_seconds(t - period.last);
	if dt > period.period {
		period.last = t;
		return true, cast(float32)dt;
	}
	return false, 0;
}
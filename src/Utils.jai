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

check :: (period: *Period, t: Apollo_Time) -> bool, float {
	dt := to_float64_seconds(t - period.last);
	if dt > period.period {
		period.last = t;
		return true, cast(float32)dt;
	}
	return false, 0;
}
pub const blip_t = opaque {};

pub extern fn blip_new(sample_count: c_int) ?*blip_t;
pub extern fn blip_delete(b: ?*blip_t) void;
pub extern fn blip_set_rates(b: ?*blip_t, clock_rate: f64, sample_rate: f64) void;
pub extern fn blip_clear(b: ?*blip_t) void;
pub extern fn blip_add_delta(b: ?*blip_t, clock_time: c_uint, delta: c_int) void;
pub extern fn blip_add_delta_fast(b: ?*blip_t, clock_time: c_uint, delta: c_int) void;
pub extern fn blip_clocks_needed(b: ?*const blip_t, sample_count: c_int) c_int;
pub extern fn blip_end_frame(b: ?*blip_t, clock_duration: c_uint) void;
pub extern fn blip_samples_avail(b: ?*const blip_t) c_int;
pub extern fn blip_read_samples(b: ?*blip_t, out: [*]i16, count: c_int, stereo: c_int) c_int;

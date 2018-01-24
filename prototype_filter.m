function h = prototype_filter()
f=[0 1/128 1/32 1];
a=[2 2 0 0];
h=firpm(511,f,a);
h=h.';

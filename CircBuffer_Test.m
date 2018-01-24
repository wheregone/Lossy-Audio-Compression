clear; close all; clc;
x = CircBuffer(9);
disp(x.size);
disp(x.pos);
disp(x.samples.');

x = x.insert([1 2 3 4]);
disp(x.size);
disp(x.pos);
disp(x.samples.');

x = x.insert([5 6]);
disp(x.size);
disp(x.pos);
disp(x.samples.');
disp(x.ordered.');
disp(x.reversed.');

x = x.insert([7 8 9 10 11 12]);
disp(x.size);
disp(x.pos);
disp(x.samples.');
disp(x.ordered.');
disp(x.reversed.');
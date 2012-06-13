f = -150000:1:150000;
T = 8.98e-6;
s = (sin(pi*T.*f)).**2 ./ (f.**2);
m = max(s);
s ./= m;
figure(1);
subplot(111);
plot(f,s);
xlabel('frequencia (Hz)');
ylabel('d.e.p. (normalizada)');
print('figure3.png', '-dpng', '-r0', '-S450,450');

figure(2);
subplot(111);
plot(f,s);
hold on;
plot(f,0.1.*(abs(f)<20000));
xlabel('frequencia (Hz)');
ylabel('d.e.p. (normalizada)');
print('figure4.png', '-dpng', '-r0', '-S450,450');


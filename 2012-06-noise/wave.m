turbor = wavread('turboR_final.wav')(:, 1);
brmsx = wavread('brmsx_final.wav')(:, 1);

function setaxis(v, ymin, ymax)
  axis([1 size(v, 1) ymin ymax])
  end

figure(1);
subplot(211);
plot(turbor, 'r');
setaxis(turbor, -1, 1);
title('turboR');
subplot(212);
plot(brmsx);
setaxis(brmsx, -1, 1);
title('BrMSX');
print('figure1.png', '-dpng', '-S400,500');

function p = power(v)
  p = filter(ones(2000, 1), 1, v .* v);
  end

figure(2);
hold off;
subplot(111);
plot(power(turbor), 'r')
hold on;
plot(power(brmsx))
legend('turboR', 'BrMSX');
print('figure2.png', '-dpng', '-S450,300');


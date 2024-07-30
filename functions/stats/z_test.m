function z_test(n1, x1, n2, x2)
% z_test(n1, x1, n2, x2)
% n is the number of recordings in group 1, x1 is the number of recordings 
% in group 1 that have the thing. same for n2/x2.
% this was code provided by ChatGPT, but the results were verified using 
% https://www.socscistatistics.com/tests/ztest

p1 = x1 / n1;
p2 = x2 / n2;

% Calculate the pooled proportion
p_hat = (x1 + x2) / (n1 + n2);

% Calculate the standard error
SE = sqrt(p_hat * (1 - p_hat) * (1/n1 + 1/n2));

% Calculate the z-test statistic
z = (p1 - p2) / SE;

% Calculate the p-value for a two-tailed test
p_value = 2 * (1 - normcdf(abs(z)));

% Display the results
fprintf('Sample proportion for population 1 (p1): %.4f\n', p1);
disp([num2str(x1),'/', num2str(n1)])
fprintf('Sample proportion for population 2 (p2): %.4f\n', p2);
disp([num2str(x2),'/', num2str(n2)])
fprintf('Pooled proportion (p_hat): %.4f\n', p_hat);
fprintf('Standard error (SE): %.4f\n', SE);
fprintf('Z-test statistic (z): %.4f\n', z);
fprintf('P-value: %.4f\n', p_value);

% Determine the significance level
alpha = 0.05;

% Make a decision
if p_value < alpha
    fprintf('Reject the null hypothesis: There is a significant difference between the two proportions.\n');
else
    fprintf('Fail to reject the null hypothesis: There is no significant difference between the two proportions.\n');
end
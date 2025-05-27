function [value] = evaluate_mu(d, u, c, theta, l, SIGMA, f)

    erfid = @(x, y) erfi(x./sqrt(2)) - erfi(y./sqrt(2));
    mu = @(d, u, c) (2/(pi*theta))*((log(1+f*(exp(SIGMA*(u - d - c))-1)) ./ erfid(u, d)) + ((log(1+f*(exp(SIGMA*(l - d - c))-1)) ./ erfid(d, l))));
    value = mu(d,u,c);
end
function [d, u]=maximize_mu_ci(c, l, SIGMA, theta, f)

    erfid = @(x, y) erfi(x./sqrt(2)) - erfi(y./sqrt(2));
    mu = @(d, u, c) (1/(theta*pi))*((log(1+f*(exp(SIGMA*(u - d - c))-1)) ./ erfid(u, d)) + ((log(1+f*(exp(SIGMA*(l - d - c))-1)) ./ erfid(d, l))));
    d=0;
    u=0;
    obj = @(x) -mu(x(1), x(2), c); 
    lb = [l + 0.01, l+c];
    ub = [0.6, 3];
    nonlcon = @(x) deal([c - (x(2) - x(1)); l - x(1);x(1) - x(2)] , []);
    x0 = [-0.5, 0.5];
    opts = optimoptions('fmincon', 'Display', 'off', ...
                'Algorithm', 'interior-point', ...
                'MaxIterations', 500, ...
                'OptimalityTolerance', 1e-8);
        try
                [xopt, fval] = fmincon(obj, x0, [], [], [], [], lb, ub, nonlcon, opts);
                d = xopt(1);
                u= xopt(2);
                mu= fval;
        catch
                d = NaN;
                u= NaN;
                mu= NaN;
        end
end
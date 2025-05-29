function [d_vals, u_vals] = maximize_mu(c_vals, l, sigma, theta, f)

        % === Funzione erfid(x,y) via integrale (reale) ===
        
        erfid = @(x, y) erfi(x./sqrt(2)) - erfi(y./sqrt(2));

        mu = @(d, u, c) (2/(theta*pi))*((log(1+f*(exp(sigma*(u - d - c))-1)) ./ erfid(u, d)) + ((log(1+f*(exp(sigma*(l - d - c))-1)) ./ erfid(d, l))));

        % === Preallocazione risultati ===
        d_vals = zeros(size(c_vals));
        u_vals = zeros(size(c_vals));
        mu_vals = zeros(size(c_vals));
        
        % === Ottimizzazione per ogni c ===
        for i = 1:length(c_vals)
            c = c_vals(i);
        
            % obiettivo da massimizzare (fmincon minimizza)
            obj = @(x) -mu(x(1), x(2), c);   % x(1) = d, x(2) = u
        
            % lb/ub compatibili
            lb = [l + 0.01, l+c];
            ub = [0.6, 3];
        
            % vincoli non lineari: u - d > c ; d > l
            nonlcon = @(x) deal([c - (x(2) - x(1)); l - x(1);x(1) - x(2)] , []);
        
            % guess iniziale vicino alla realtà
            x0 = [-0.5, 0.5];
        
            % opzioni fmincon
            opts = optimoptions('fmincon', 'Display', 'off', ...
                'Algorithm', 'interior-point', ...
                'MaxIterations', 500, ...
                'OptimalityTolerance', 1e-8);
        
            % risolvi
            try
                [xopt, fval] = fmincon(obj, x0, [], [], [], [], lb, ub, nonlcon, opts);
                d_vals(i) = xopt(1);
                u_vals(i) = xopt(2);
                mu_vals(i) = fval;
            catch
                d_vals(i) = NaN;
                u_vals(i) = NaN;
                mu_vals(i) = NaN;
            end
        end
        
end
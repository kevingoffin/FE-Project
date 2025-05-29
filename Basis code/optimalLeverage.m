function [opt_lev] = optimalLeverage(SIGMA, theta, c, l, max_leverage)
    % Funzioni ausiliarie
    erfid = @(x, y) erfi(x / sqrt(2)) - erfi(y / sqrt(2));  % Errore integrale normalizzato
    
    % Probabilità p^+ e p^- (Eq. 17 del paper)
    p_plus = @(d, u) erfid(d, l) / erfid(u, l);
    p_minus = @(d, u) 1 - p_plus(d, u);
    
    % Payoff v^+ e v^- (Eq. 7 del paper)
    v_plus = @(d, u) exp(SIGMA * (u - d - c)) - 1;
    v_minus = @(d, u) exp(SIGMA * (l - d - c)) - 1;
    
    % Probabilità "fair" q^+ (Eq. 10 del paper)
    q_plus = @(d, u) v_minus(d, u) / (v_minus(d, u) - v_plus(d, u));
    
    % Leva ottimale f^* (Eq. 12 del paper)
    f_star = @(d, u) -(p_plus(d, u) / v_minus(d, u) + p_minus(d, u) / v_plus(d, u));
    
    % Rendimento μ (Eq. 23 del paper)
    mu = @(d, u) (2 / (theta * pi)) * ( ...
        log(1 + f_star(d, u) * v_plus(d, u)) / erfid(u, d) + ...
        log(1 + f_star(d, u) * v_minus(d, u)) / erfid(d, l) ...
    );
    
    % Vincoli per d e u:
    % - l < d < 0 (entry band sotto la media)
    % - u > 0 (exit band sopra la media)
    % - u - d > c (condizione per evitare costi di transazione eccessivi)
        lb = [l + 0.01, l+c];
        ub = [0.6, 3];
               % Upper bounds: d < 0, u libero
    
    % Funzione obiettivo da massimizzare (-mu perché 'fmincon' minimizza)
    objective = @(x) -mu(x(1), x(2));
    
    % Punto iniziale per l'ottimizzazione (es. valori medi)
    x0 = [-0.5, 0.5];  % d a metà tra l e 0, u = 0.5
    
    % Ottimizzazione con 'fmincon'
    options = optimoptions('fmincon', 'Display', 'off');
    [opt_du, ~] = fmincon(objective, x0, [], [], [], [], lb, ub, [], options);
    
    % Estrai d* e u* ottimali
    opt_d = opt_du(1);
    opt_u = opt_du(2);
    
    % Calcola la leva ottimale f^* con d* e u*
    opt_f_star = f_star(opt_d, opt_u);
    
    % Applica il vincolo di leva massima
    opt_lev = min(opt_f_star, max_leverage);
    
end
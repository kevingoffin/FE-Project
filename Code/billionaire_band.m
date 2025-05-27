function [m3_return] = billionaire(X_OS, d_star, u_star, l, c, SIGMA, f)

    % X_OS      vettore del processo normalizzato (non centrato, come lo passi tu)
    % d_star    soglia inferiore in unità *non* di SIGMA
    % u_star    soglia superiore in unità *non* di SIGMA
    % l         stop-loss in unità *non* di SIGMA
    % c         costo trans. normalizzato in unità di SIGMA
    % SIGMA     deviazione stazionaria usata per riportare X_OS allo scale
    %
    % Ritorna rendimento trimestrale m3_return
    
    flag_long  = false;   % se true, siamo in posizione long aperta
    flag_short = false;   % se true, siamo in posizione short aperta
    wlt = 1;
    
    % uso i valori in scala "reale": soglia*SIGMA

    cost = 2*c;    % due costi (entry+exit)
    v_pls = exp(SIGMA*(u_star - d_star - cost)) -1;
    v_mns = exp(SIGMA*(l - d_star - cost)) -1;
    
    for i = 2:length(X_OS)
        x_prev = X_OS(i-1);
        x_curr = X_OS(i);
        
        %% 1) LONG: entro quando supero d* e vengo da dentro la banda
        if ~flag_long && ~flag_short && x_curr >= d_star && x_prev < d_star && x_prev > l
            flag_long = true;
        end
        % esco in profit al superamento di u*
        if flag_long && x_curr >= u_star
            wlt = wlt*(1+f*v_pls);
            disp('sono nel iff long if\n')
            flag_long = false;
        end
        % stop-loss per long: scendo sotto l
        if flag_long && x_curr <= l
            wlt = wlt*(1+f*v_mns);
            flag_long = false;
        end
        
        %% 2) SHORT (entry a −d*, exit profit a −u*, stop-loss a −l)
        % soglie per la gamba short
        
        
        % — entry: X sale e supera −d*, partendo da dentro la fascia (fra −u* e d*)
        if ~flag_short && ~flag_long && x_curr >= -d_star && x_prev < -d_star && x_prev > -u_star
            flag_short = true;
        end
        
        % — exit profit: X scende sotto −u*
        if flag_short && x_curr <= -u_star
            wlt = wlt * (1 + f * v_pls);   % stesso moltiplicatore del long
            wlt
            disp('sono nel iff short if\n')
            flag_short = false;
        end
        
        % — stop-loss: X sale sopra −l (va troppo contro la short)
        if flag_short && x_curr >= -l
            wlt = wlt * (1 + f * v_mns);   % stessa perdita del long
            flag_short = false;
        end
    end

    m3_return =log(wlt);
    % restituisci rendimento trimestrale
    
end
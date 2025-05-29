function [Rt, timestamp, bid_HO, bid_LGO, ask_HO, ask_LGO]= dataset_preparation(T)
timestamp = T{:, 2};      % Timestamp
bid_HO    = T{:, 3};      % Bid HO
bid_LGO   = T{:, 4};      % Bid LGO
ask_HO    = T{:, 7};      % Ask HO
ask_LGO   = T{:, 8};      % Ask LGO

% Filtra righe valide (dove tutti i dati sono disponibili)
valid_idx = ~isnan(bid_HO) & ~isnan(ask_HO) & ~isnan(bid_LGO) & ~isnan(ask_LGO);
timestamp = timestamp(valid_idx);

conv_HO = 42;   % converter
conv_LGO = 7.45;

bid_HO = bid_HO(valid_idx)*conv_HO;
ask_HO = ask_HO(valid_idx)*conv_HO;
bid_LGO = bid_LGO(valid_idx)/conv_LGO;
ask_LGO = ask_LGO(valid_idx)/conv_LGO;

% Calcola i mid-price
mid_HO = (bid_HO + ask_HO) / 2;
mid_LGO = (bid_LGO + ask_LGO) / 2;


% Calcola Rt
Rt = log(mid_HO ./ mid_LGO);

end
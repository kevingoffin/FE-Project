function plot_c_histogram(C, SIGMA)
edges = 0:0.0028:0.45;
figure;
histogram(C./SIGMA, edges, ...
          'Normalization','probability', ...   % <-- qui la differenza!
          'FaceColor',[0.2 0.6 0.8], ...
          'EdgeColor',[0.1 0.3 0.4]);
end
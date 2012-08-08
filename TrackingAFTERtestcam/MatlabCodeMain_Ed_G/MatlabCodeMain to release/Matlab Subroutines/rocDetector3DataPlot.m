function rocDetector3DataPlot

load rocDetector3Data

figure
plot(ProbabilisticRoc(:,2),ProbabilisticRoc(:,1),'r-'); xlim([0 1]); ylim([0 1]);
hold on;
plot(AdaboostRoc(:,2),AdaboostRoc(:,1),'b-'); xlim([0 1]); ylim([0 1]);
xlabel('p(False Positive)');
ylabel('p(Hit)');
set(gca,'Box','Off');
legend('Probabilistic', 'Adaboost');

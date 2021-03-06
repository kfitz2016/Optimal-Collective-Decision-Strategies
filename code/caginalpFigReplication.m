% These are booleans that refer to which figures in "Decision Dynamics in 
% Groups with Interacting Members" (Caginalp & Doiron) are to be
% replicated.
fig1 = 1;
fig2 = 0;
fig3 = 0;

if fig1 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    p = parameters([]);
    [X1,X2,~,~,~] = diffusionTrial_twoAgent(p,0);
    
    figure(1)
    plot(0:p.dt:p.dt*(length(X1)-1), X1,'g-'); hold on
    %plot(0:p.dt:p.dt*(length(X2)-1), X2,'r-'); 
    plot([0 p.dt*(length(X1)-1)],[0 0],'k-'); hold off
    ylim([min(p.L1,p.L2) max(p.H1,p.H2)]);
    xlabel('t','FontSize',12)
    ylabel('X(t)','FontSize',12,'Rotation',0)
end

if fig2 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %qvec = 1;%[.45,1,1.85];
    
    % sets the values for each agent's upper and lower threshold, oredered
    % as H1, L1, H2, L2
    biasVec = {[1,-1,1,-1], ...
        [1.75,-.25,1.75,-.25], ...
        [1.75,-.25,1,-1], ...
        [1.75,-.25,.25,-1.75]}; 
    
    for j=1:length(biasVec)
        p = parameters('H1',biasVec{j}(1), 'L1',biasVec{j}(2), ...
                       'H2',biasVec{j}(3), 'L2',biasVec{j}(4));
        
        N = 10000;
        [passTimes1, ~, passTimes2, ~] = passageTimes_twoAgent(p, N, 0);
        
        w = .02; % histogram bin width
        % bins are identified by their midpoints
        bins = (w/2:w:round( max(max(passTimes1), max(passTimes2)), ...
            round(log10(1/w)) )+w/2)';
        
        % store first passage time densities for each agent
        FPTD1 = zeros(length(bins),1); FPTD2 = zeros(length(bins),1);
        for i=1:length(bins)
            FPTD1(i) = length(find(passTimes1 >= w*(i-1) & passTimes1 < w*i))/N/w;
            FPTD2(i) = length(find(passTimes2 >= w*(i-1) & passTimes2 < w*i))/N/w;
        end
        
        % store theoretical FPT densities (for comparison on the plots)
        theory1H = cond_FPT_density(p, p.H1, p.mu1, 1, w, length(bins));
        theory2H = cond_FPT_density(p, p.H2, p.mu2, 2, w, length(bins));
        
        % plot the upper threshold FPT densities
        figure(j)
        bar(bins,FPTD1,'FaceColor','b'); hold on
        bar(bins,FPTD2,'FaceColor','r'); 
        plot(0:w:w*length(bins), theory1H, '-b', 'LineWidth', 2); 
        plot(0:w:w*length(bins), theory2H, '-r', 'LineWidth', 2); hold off
        title(['\mu_1=' num2str(p.mu1) ', \mu_2=' num2str(p.mu2) ...
            ', q_+ = q_- = ' num2str(p.qp) ', H_1 = ' num2str(p.H1) ...
            ', L_1 = ' num2str(p.L1) ', H_2 = ' num2str(p.H2) ', L_2 = ' ...
            num2str(p.L2)])
        xlabel('t','FontSize',12)
        ylabel('First Passage Time Density (+ threshold)','FontSize',12)
        legend('Agent 1', 'Agent 2')
    end
end

if fig3 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    qvec = [.45,1,1.85]; % range of kick values
    theta1Vec = 0:.1:1; % range of threshold values
    
    % keep track of 'instantaneous' second decisions
    instantCount = zeros(length(theta1Vec),length(qvec));
    % keep track of 'diffused' second decisions
    diffCount = zeros(length(theta1Vec),length(qvec));
    
    N = 2000;
    for k=1:length(qvec)
        for j=1:length(theta1Vec)
            p = parameters('qp',qvec(k),'qn',qvec(k), ...
                'H1',theta1Vec(j),'L1',-theta1Vec(j));
            
            for i=1:N
                [~,~,over1,over2,instant] = diffusionTrial_twoAgent(p,0);
                if over1 && over2
                    if instant
                        instantCount(j,k) = instantCount(j,k)+1;
                    else
                        diffCount(j,k) = diffCount(j,k)+1;
                    end
                end
            end
        end
    end
    
    % plot total probability of both deciding at upper boundary
    figure(1) 
    plot(theta1Vec,instantCount(:,1)/N+diffCount(:,1)/N, '-b'); hold on
    plot(theta1Vec,instantCount(:,2)/N+diffCount(:,2)/N, '-g');
    plot(theta1Vec,instantCount(:,3)/N+diffCount(:,3)/N, '-r');
    title('Total Probability')
    xlabel('\theta_1','FontSize',12)
    ylabel('P_{++}','FontSize',12)
    legend(['q_+ = q_- = ' num2str(qvec(1))], ...
        ['q_+ = q_- = ' num2str(qvec(2))], ...
        ['q_+ = q_- = ' num2str(qvec(3))])
    hold off
    
    % plot probability portion only from instantaneous second decisions
    figure(2) 
    plot(theta1Vec,instantCount(:,1)/N, '-b'); hold on
    plot(theta1Vec,instantCount(:,2)/N, '-g');
    plot(theta1Vec,instantCount(:,3)/N, '-r');
    title('Instantaneous Probability')
    xlabel('\theta_1','FontSize',12)
    ylabel('P_{++}','FontSize',12)
    legend(['q_+ = q_- = ' num2str(qvec(1))], ...
        ['q_+ = q_- = ' num2str(qvec(2))], ...
        ['q_+ = q_- = ' num2str(qvec(3))])    
    hold off
    
    % plot probability portion only from diffused second decisions
    figure(3) 
    plot(theta1Vec,diffCount(:,1)/N, '-b'); hold on
    plot(theta1Vec,diffCount(:,2)/N, '-g');
    plot(theta1Vec,diffCount(:,3)/N, '-r');
    title('Diffusion Probability')
    xlabel('\theta_1','FontSize',12)
    ylabel('P_{++}','FontSize',12)
    legend(['q_+ = q_- = ' num2str(qvec(1))], ...
        ['q_+ = q_- = ' num2str(qvec(2))], ...
        ['q_+ = q_- = ' num2str(qvec(3))])    
    hold off
end


function density = cond_FPT_density(p, loc, mu, agent, dt, steps)
% Returns the FPT density (as a vector) conditioned on agent 'agent' 
% deciding first at location 'loc'. Evaluates times t=0 to t=dt*steps.
% 
% See eqn 5 in Caginalp, as well as
% https://en.wikipedia.org/wiki/Numerical_integration#Integrals_over_infinite_intervals
% for the integration method used below.

    N = 10; % number of images in Green's function soln
    
    density = zeros(steps+1, 1);
    sumAreas = density;
    for i=1:steps+1
        t = dt*(i-1);
        if t==0
            t = eps;
        end
        density(i) = -sign(loc)*p.D*dcdx(p,loc,t,agent,N,mu);
        sumAreas(i) = integrateFPT_0toInf(t, mod(agent,2)+1);
    end
    
    density = density .* sumAreas;
    
    
    
    function sum = integrateFPT_0toInf(tloc, agent)
        ts = linspace(0,1,100);
        if agent == 1
            sum = (-p.D*dcdx(p,p.H1,tloc,1,N,mu) + ...
                p.D*dcdx(p,p.L1,tloc,1,N,mu)) / 2;
            for j=2:length(ts)-1
                sum = sum + (-p.D*dcdx(p,p.H1,tloc+ts(j)/(1-ts(j)),1,N,mu) + ...
                p.D*dcdx(p,p.L1,tloc+ts(j)/(1-ts(j)),1,N,mu)) / (1-ts(j))^2;
            end
            sum = sum * (ts(2)-ts(1));
        else
            sum = (-p.D*dcdx(p,p.H2,tloc,2,N,mu) + ...
                p.D*dcdx(p,p.L2,tloc,2,N,mu)) / 2;
            for j=2:length(ts)-1
                sum = sum + (-p.D*dcdx(p,p.H2,tloc+ts(j)/(1-ts(j)),2,N,mu) + ...
                p.D*dcdx(p,p.L2,tloc+ts(j)/(1-ts(j)),2,N,mu)) / (1-ts(j))^2;
            end
            sum = sum * (ts(2)-ts(1));
        end
    end

end
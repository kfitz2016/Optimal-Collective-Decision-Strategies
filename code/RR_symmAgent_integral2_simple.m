function RR = RR_symmAgent_integral2_simple(p, X, TI, N)
% (Uses MATLAB's "integral2" function throughout the reward rate 
% calculation process.)

% Calculates expected reward rate for two agents in consecutive
% environments with random probability of positive or negative associated
% drift, where decisions are separated by time TI. Agents are "symmetric"
% in the sense that they set decision thresholds at the same (possibly
% asymmetric) values, they receive the same (possibly asymmetric) "kick" 
% from the other agent when it is the first to decide at a boundary, and
% they receive the same (possibly asymmetric) reward upon decision at the
% boundary that matches the drift of the current environment. For 
% simplicity, we assume that agents are in a mu=1 or mu=-1 environment each
% with probability 1/2. Due to agent symmetry, WLOG we perform all
% calculations for one agent, conditioning on the other agent deciding 
% first if applicable. N is the number of image terms to use in the
% probability densities that solve the Focker-Planck equation.

% set parameters contained in 'X' explicitly for maximization routine
p = parameters('p', p, 'H1', X(1), 'L1', X(2), 'qp1', X(3), 'qn1', X(4));

%tic;
r = exp_reward(p, N);
%T=toc;
TL = exp_TL(p, N);
RR = 2*r / (TL + TI); 
end

function r = exp_reward(p, N)
% Expected reward for each agent across all environments, WLOG agent 1.
fH_cond_inf_P = @(t1,t2) fH(t1,1,p,N).*(fH(t2,1,p,N)+fL(t2,1,p,N));
fL_cond_inf_N = @(t1,t2) fL(t1,-1,p,N).*(fH(t2,-1,p,N)+fL(t2,-1,p,N));

probAtUpper = 1/2 * ( P_crossBefore(fH_cond_inf_P) + ...
    P_instCrossAfter(p, fH_cond_inf_P, p.H1, 1, N) );
probAtLower = 1/2 * ( P_crossBefore(fL_cond_inf_N) + ...
    P_instCrossAfter(p, fL_cond_inf_N, p.L1, -1, N) );
r = p.R1p/2 * probAtUpper + p.R1n/2 * probAtLower;
end

function TL = exp_TL(p, N)
% Expected time for the last agent to make a decision (WLOG for agent 2 to
% decide, conditioned on agent 1 deciding first).
%tic;
tf = 10;
TL = integral2(@(t1,t2) t1.*fH(t1,1,p,N).*fH(t2,1,p,N),0,tf,@(t1)t1,tf,'AbsTol',1e-10) + ...
    integral2(@(t1,t2) t1.*fH(t1,1,p,N).*fL(t2,1,p,N),0,tf,@(t1)t1,tf,'AbsTol',1e-10) + ...
    integral2(@(t1,t2) t1.*fL(t1,1,p,N).*fH(t2,1,p,N),0,tf,@(t1)t1,tf,'AbsTol',1e-10) + ...
    integral2(@(t1,t2) t1.*fL(t1,1,p,N).*fL(t2,1,p,N),0,tf,@(t1)t1,tf,'AbsTol',1e-10) + ...
    integral2(@(t1,t2) t1.*fH(t1,-1,p,N).*fH(t2,-1,p,N),0,tf,@(t1)t1,tf,'AbsTol',1e-10) + ...
    integral2(@(t1,t2) t1.*fH(t1,-1,p,N).*fL(t2,-1,p,N),0,tf,@(t1)t1,tf,'AbsTol',1e-10) + ...
    integral2(@(t1,t2) t1.*fL(t1,-1,p,N).*fH(t2,-1,p,N),0,tf,@(t1)t1,tf,'AbsTol',1e-10) + ...
    integral2(@(t1,t2) t1.*fL(t1,-1,p,N).*fL(t2,-1,p,N),0,tf,@(t1)t1,tf,'AbsTol',1e-10);
%TL = integral2(@(t1,t2) t1.*((fH(t1,1,p,N)+fL(t1,1,p,N)).*(fH(t2,1,p,N)+fL(t2,1,p,N)) + ...
%    (fH(t1,-1,p,N)+fL(t1,-1,p,N)).*(fH(t2,-1,p,N)+fL(t2,-1,p,N))), ...
%    0,tf,0,@(t1)t1,'AbsTol',1e-6);
%TL = integral2(@(t1,t2) t1.*(fH(t1,1,p,N)+fL(t1,1,p,N)).*(fH(t2,1,p,N)+fL(t2,1,p,N)), ...
%    0,tf,0,@(t1)t1,'AbsTol',1e-6) + ...
%    integral2(@(t1,t2) t1.*(fH(t1,-1,p,N)+fL(t1,-1,p,N)).*(fH(t2,-1,p,N)+fL(t2,-1,p,N)), ...
%    0,tf,0,@(t1)t1,'AbsTol',1e-6);
%T4 = toc
end

function P = P_crossBefore(fthresh_cond_inf)
% Probability that one agent crosses the decision threshold at "thresh",
% given that it decides before the other agent.
%tic;
tf = 10;%inf;
P = integral2(@(t1,t2) fthresh_cond_inf(t1,t2),0,tf,@(t1)t1,tf,'AbsTol',1e-10);
%T1 = toc
end

function P = P_instCrossAfter(p, fthresh_cond_inf, thresh, mu, N)
% Probability that one agent is instantaneously "kicked" across the 
% decision threshold at "thresh", given the other agent's crossing of 
% "thresh" before.
%tic;
tf = 10;%inf;
if sign(thresh) == 1
    P = integral2(@(t1,t2) fthresh_cond_inf(t1,t2).*(intc_x(p,thresh,t1,1,N,mu) ...
        - intc_x(p,max([p.L1 (p.H1-p.L1)/2-p.qp1]),t1,1,N,mu)) ./ rhoDenom(t1,mu,p,N), ...
        0,tf,@(t1)t1,tf,'AbsTol',1e-10);
elseif sign(thresh) == -1
    P = integral2(@(t1,t2) fthresh_cond_inf(t1,t2).*(intc_x(p,min([p.H1 (p.H1-p.L1)/2+p.qn1]),t1,1,N,mu) ...
        - intc_x(p,thresh,t1,1,N,mu)) ./ rhoDenom(t1,mu,p,N), ...
        0,tf,@(t1)t1,tf,'AbsTol',1e-10);
end
%T2 = toc
end

function val = fH(t,mu,p,N)
    val = -p.D * dcdx(p,p.H1,t,1,N,mu);
end

function val = fL(t,mu,p,N)
    val = p.D * dcdx(p,p.L1,t,1,N,mu);
end

function val = rhoDenom(t,mu,p,N)
    val = intc_x(p,p.H1,t,1,N,mu) - intc_x(p,p.L1,t,1,N,mu);
    val(abs(val)<=sqrt(realmin)) = sqrt(realmin);
end
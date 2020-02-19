function GnssTimeofWeek2DP(CycleSec, GnssSec)
% GNSSTIMEOFWEEK2DP(CYCLESEC, GNSSSEC)
% Where CYCLESEC is the Time according to the 20ms cycle counter of the
% UAVC and GNSSSEC is the Time according to the GNSS.

DayTime = GnssSec-floor(GnssSec/(24*3600))*24*3600;

StartTime = DayTime - CycleSec;

Hours = floor(StartTime/3600);
Minutes = floor((StartTime - Hours*3600)/60);
Seconds = StartTime - Hours*3600 - Minutes*60;
disp([num2str(Hours, '%02.0f'), ':', num2str(Minutes, '%02.0f'), ':', num2str(Seconds, '%02.3f')])

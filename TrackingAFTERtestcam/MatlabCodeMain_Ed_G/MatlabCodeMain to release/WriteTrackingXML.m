function [framexmlfile, xmlFileName]= WriteTrackingXML( TrackingData, Targetpath, framenumber)

%clear all
clc

%**************************************************************************
% This module converts the tracking data into an XML file so the 3DiCampus
% environment written by Larry can access the generated xml file
%**************************************************************************

% TrackingData = [ 20 40;
%                   30 50; ];
% 
% Targetpath = 'C:\EC\York\GEOIDEWork2011\HwyVideoForiCampusDemo\SampleXML_fromLarry';

% Assume that your data is available in arrays TrackingData and arrData2. 
% Create an XML document node, say "persons" as follows:
docNode = com.mathworks.xml.XMLUtils.createDocument('persons');
docRootNode = docNode.getDocumentElement;

% Now put the data in the data nodes..
if( ~isempty(TrackingData) )
        for i=1:size(TrackingData,1)
            % create nodes..
                elPar = docNode.createElement('person');
                elData1 = docNode.createElement('lat');
                elData2 = docNode.createElement('lon');

            % put data in nodes..
                elData1.appendChild( docNode.createTextNode(sprintf('%f', TrackingData(i,1))) );
                elData2.appendChild( docNode.createTextNode(sprintf('%f', TrackingData(i,2))) );

            % put nodes in the correct positions..
                elPar.appendChild(elData1);
                elPar.appendChild(elData2);
               
                docRootNode.appendChild(elPar);
        end
        % Now save the XML document
        %xmlFileName = ['TrackingResults','.xml'];
        %xmlFileName = ['C:\EC\York\GEOIDEWork2011\HwyVideoForiCampusDemo\SampleXML_fromLarry\TrackingResults','.xml'];
        xmlFileName = strcat(Targetpath, '\TrackingResults.xml'); 
        
        xmlwrite(xmlFileName, docNode);
        %edit(xmlFileName);  
else
        % create nodes..
        elPar = docNode.createElement('person');
        elData1 = docNode.createElement('lat');
        elData2 = docNode.createElement('lon');

        % Now save the XML document
        %xmlFileName = ['TrackingResults','.xml'];
        xmlFileName = strcat(Targetpath, '\TrackingResults.xml'); 
        xmlwrite(xmlFileName, docNode);
        %edit(xmlFileName);      
    
end
framexmlfile=strcat(Targetpath, '\frame.xml');
fid = fopen(framexmlfile,'w');
fprintf(fid, '<frames>\n');
fprintf(fid,'<frame no="%d"/>\n',framenumber);
fprintf(fid, '</frames>\n');
fclose(fid);


return
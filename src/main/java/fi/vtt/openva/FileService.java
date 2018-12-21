package fi.vtt.openva;
//OpenVA - Open software platform for visual analytics
//
//Copyright (c) 2018, VTT Technical Research Centre of Finland Ltd
//All rights reserved.
//Redistribution and use in source and binary forms, with or without
//modification, are permitted provided that the following conditions are met:
//
// 1) Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
// 2) Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
// 3) Neither the name of the VTT Technical Research Centre of Finland nor the
//    names of its contributors may be used to endorse or promote products
//    derived from this software without specific prior written permission.
//
//THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS IS'' AND ANY
//EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS AND CONTRIBUTORS BE LIABLE FOR ANY
//DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
/*
* OpenVAApp
*
* Spring Boot application (context) initialization.
*/
import java.io.File;
import java.io.IOException;
import java.net.URL;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import java.util.stream.Collectors;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

/**
 *  OpenVAApp.
 *
 * @author Pekka Siltanen
 */


// Every day delete all files older than one day from temporary file folder
@Service
public class FileService {
	 @Value("${rinterface.outputfolder}")
	private String staticURI;
	
	@Scheduled(fixedDelay = 86400000)
	public void sheduledFileService() throws Exception {
		if (staticURI!= null && !staticURI.equals("")) {
			Path staticPath = Paths.get(new URL(staticURI).toURI());
			String folderName = staticPath.toAbsolutePath().toString().replace('\\', '/');
			findFiles(folderName);
		}
	}

    public void findFiles(String filePath) throws IOException {
        List<File> files = Files.list(Paths.get(filePath))
                                .map(path -> path.toFile())
                                .collect(Collectors.toList());
        for(File file: files) {
            if(file.isDirectory()) {
                findFiles(file.getAbsolutePath());
            } else if(isFileOld(file)){
                deleteFile(file);
            }
        }

    }

    public void deleteFile(File file) {
        file.delete();
    }

    public boolean isFileOld(File file) {
        LocalDate fileDate = Instant.ofEpochMilli(file.lastModified()).atZone(ZoneId.systemDefault()).toLocalDate();
        LocalDate oldDate = LocalDate.now().minusDays(1);
        return fileDate.isBefore(oldDate);
    }


}

// OpenVA - Open software platform for visual analytics
//
// Copyright (c) 2018, VTT Technical Research Centre of Finland Ltd
// All rights reserved.
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
//    1) Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//    2) Redistributions in binary form must reproduce the above copyright
//       notice, this list of conditions and the following disclaimer in the
//       documentation and/or other materials provided with the distribution.
//    3) Neither the name of the VTT Technical Research Centre of Finland nor the
//       names of its contributors may be used to endorse or promote products
//       derived from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS IS'' AND ANY
// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS AND CONTRIBUTORS BE LIABLE FOR ANY
// DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
/**
 * UserPrincipal.
 *
 * @author Markus Ylikerälä, Pekka Siltanen
 */
package fi.vtt.openva;

import java.util.Collection;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import fi.vtt.openva.domain.Account;

public class UserPrincipal  implements UserDetails{
	private static final long serialVersionUID = 7649614807058895611L;
	private Account account;
 
    public UserPrincipal(Account account) {
        this.account = account;
    }
     
	@Override
	public Collection<? extends GrantedAuthority> getAuthorities() {
		return null;
	} 
 
    public String getPassword() {
        return account.getPassword();   
    }
 
    public String getUsername() {
        // TODO Auto-generated method stub
        return account.getUsername();
    }
 
    public boolean isAccountNonExpired() {
        // TODO Auto-generated method stub
        return true;
    }
 
    public boolean isAccountNonLocked() {
        // TODO Auto-generated method stub
        return true;
    }
 
    public boolean isCredentialsNonExpired() {
        // TODO Auto-generated method stub
        return true;
    }
 
    public boolean isEnabled() {
        return true;
    }
}

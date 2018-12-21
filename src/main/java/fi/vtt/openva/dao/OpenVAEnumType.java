/**
 * 
 */
package fi.vtt.openva.dao;

import java.io.Serializable;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.HashMap;

import org.hibernate.HibernateException;
import org.hibernate.engine.spi.SessionImplementor;
//import org.hibernate.engine.spi.SharedSessionContractImplementor;
import org.hibernate.usertype.UserType;

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

/**
 * OpenVAEnumType.
 *
 * @author Markus Ylikerälä
 * 
 * Note: all Enums will hopefully become obsolete when the database is redesigned
 */
public class OpenVAEnumType<T,E extends Enum<E>>  implements UserType, Serializable {

	/** The sql type. */
	protected int sqlType;
	 
 	/** The clazz. */
 	protected Class<E> clazz = null;
     
     /** The enum map. */
     protected HashMap<String, E> enumMap;
     
     /** The value map. */
     protected HashMap<E, String> valueMap;

     /**
      * Instantiates a new generic enum type.
      */
     public OpenVAEnumType(){
//    	   enumMap = new HashMap<String, E>();
//           valueMap = new HashMap<E, String>();
     }
     
     /**
      * Instantiates a new generic enum type.
      *
      * @param clazz the clazz
      * @param enumValues the enum values
      * @param method the method
      * @param sqlType the sql type
      * @throws NoSuchMethodException the no such method exception
      * @throws InvocationTargetException the invocation target exception
      * @throws IllegalAccessException the illegal access exception
      */
     public OpenVAEnumType(Class<E> clazz,
              E[] enumValues, String method, int sqlType) throws
          NoSuchMethodException, InvocationTargetException,
          IllegalAccessException
     {
          this.clazz = clazz;
          enumMap = new HashMap<String, E>(enumValues.length);
          valueMap = new HashMap<E, String>(enumValues.length);
          Method m = clazz.getMethod(method);

          for (E e: enumValues) {
           
              @SuppressWarnings("unchecked")
              T value = (T)m.invoke(e);
               
              enumMap.put(value.toString(), e);
              valueMap.put(e, value.toString());
         }
         this.sqlType = sqlType;
     }

     /* (non-Javadoc)
      * @see org.hibernate.usertype.UserType#assemble(java.io.Serializable, java.lang.Object)
      */
     public Object assemble(Serializable cached, Object owner)
     throws HibernateException {
           return cached;
     }

     /* (non-Javadoc)
      * @see org.hibernate.usertype.UserType#deepCopy(java.lang.Object)
      */
     public Object deepCopy(Object obj) throws
     HibernateException
     {
           return obj;
     }

     /* (non-Javadoc)
      * @see org.hibernate.usertype.UserType#disassemble(java.lang.Object)
      */
     public Serializable disassemble(Object obj) throws
     HibernateException
     {
          return (Serializable)obj;
     }

     /* (non-Javadoc)
      * @see org.hibernate.usertype.UserType#equals(java.lang.Object, java.lang.Object)
      */
     public boolean equals(Object obj1, Object obj2) throws
     HibernateException
     {
           if (obj1 == obj2) {
                 return true;
           }

           if (obj1 == null || obj2 == null) {
                 return false;
           }
           return obj1.equals(obj2);
     }

     /* (non-Javadoc)
      * @see org.hibernate.usertype.UserType#hashCode(java.lang.Object)
      */
     public int hashCode(Object obj) throws HibernateException
     {
    	 	assert (obj != null);
           return obj.hashCode();
     }

     /* (non-Javadoc)
      * @see org.hibernate.usertype.UserType#isMutable()
      */
     public boolean isMutable()
     {
           return false;
     }

//     public Object nullSafeGet(ResultSet rs, String[] names, Object owner)
//     throws HibernateException, SQLException
//     {
//           String value = rs.getString(names[0]);
//           if (!rs.wasNull()) {
//                 return enumMap.get(value);
//           }
//           return null;
//     }
//
//     public void nullSafeSet(PreparedStatement ps, Object obj, int index)
//     throws HibernateException, SQLException
//     {
//             if (obj == null) {
//                   ps.setNull(index, sqlType);
//             } else {
//                   ps.setObject(index, valueMap.get(obj), sqlType);
//             }
//     }

     /* (non-Javadoc)
 * @see org.hibernate.usertype.UserType#replace(java.lang.Object, java.lang.Object, java.lang.Object)
 */
public Object replace(Object original, Object target, Object owner)
     throws HibernateException
     {
             return original;
     }

     /* (non-Javadoc)
      * @see org.hibernate.usertype.UserType#returnedClass()
      */
     public Class<E> returnedClass() {
             return clazz;
     }

     /* (non-Javadoc)
      * @see org.hibernate.usertype.UserType#sqlTypes()
      */
     public int[] sqlTypes()
     {
             return new int[] {sqlType};
     }

//	public Object nullSafeGet(ResultSet rs, String[] names, SharedSessionContractImplementor ssci, Object owner)
//			throws HibernateException, SQLException {
//	//	return nullSafeGet(rs, names, ssci, owner);
//		
//		   String value = rs.getString(names[0]);
//           if (!rs.wasNull()) {
//                 return enumMap.get(value);
//           }
//           return null;
//           
//	}
//
//	public void nullSafeSet(PreparedStatement ps, Object obj, int index, SharedSessionContractImplementor ssci)
//			throws HibernateException, SQLException {
//		//nullSafeSet(ps, obj, index, ssci);
//		   if (obj == null) {
//               ps.setNull(index, sqlType);
//         } else {
//        	 //System.err.println(index + "#" + valueMap + "#" + obj + "\t" + valueMap.get(obj));
////        	 if(valueMap.get(obj) == null){
////        		         		 
////        		  //enumMap.put(obj.toString(), obj);
////                  //valueMap.put(obj, obj.toString());
////        	 }
//               ps.setObject(index, valueMap.get(obj), sqlType);
//         }
//	}

	/* (non-Javadoc)
 * @see org.hibernate.usertype.UserType#nullSafeGet(java.sql.ResultSet, java.lang.String[], org.hibernate.engine.spi.SessionImplementor, java.lang.Object)
 */
@Override
	public Object nullSafeGet(ResultSet rs, String[] names, SessionImplementor arg2, Object arg3)
			throws HibernateException, SQLException {
		// TODO Auto-generated method stub
		//return null;
		
		 String value = rs.getString(names[0]);
         if (!rs.wasNull()) {
               return enumMap.get(value);
         }
         return null;
	}

	/* (non-Javadoc)
	 * @see org.hibernate.usertype.UserType#nullSafeSet(java.sql.PreparedStatement, java.lang.Object, int, org.hibernate.engine.spi.SessionImplementor)
	 */
	@Override
	public void nullSafeSet(PreparedStatement arg0, Object arg1, int arg2, SessionImplementor arg3)
			throws HibernateException, SQLException {
		// TODO Auto-generated method stub
		
	}
}

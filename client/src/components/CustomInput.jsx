import React from 'react'
import styles from '../styles'

//forward slash, ^ is caret sign, A-Z all uppercase, a-z lowercase, 0-9 digits these are the only valid player name characters

const regex = /^[A-Za-z0-9]+$/;
const CustomInput = ({ Label, placeholder, value, handleValueChange }) => {
    return (
        <>
            <label htmlFor='name' className='styles.label'>{Label}
            </label>
            <input
                type="text"
                placeholder={placeholder}
                value={value}
                //callback func where we get an event
                onChange={(e) => {
                    //special chars not allowed
                    //if string is not empty or if regex test is passed by it
                    if (e.target.value === '' || regex.test(e.target.value)) handleValueChange(e.target.value);
                }}
                className={styles.input}
            />
        </>
    )
}

export default CustomInput

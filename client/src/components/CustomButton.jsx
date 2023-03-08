import React from 'react'
import styles from '../styles'

//pass props
const CustomButton = ({title, handleClick, restStyles}) => {
  return (
    <button
        type='button'
        //What is this dollar, learn
        className={`${styles.btn} ${restStyles}`}
        onClick={handleClick}
    >
        {title}
    </button>
  )
}

export default CustomButton

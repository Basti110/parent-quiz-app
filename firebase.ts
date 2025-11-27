// Import the functions you need from the SDKs you need
import { initializeApp } from "firebase/app";
import { getAnalytics } from "firebase/analytics";
// TODO: Add SDKs for Firebase products that you want to use
// https://firebase.google.com/docs/web/setup#available-libraries

// Your web app's Firebase configuration
// For Firebase JS SDK v7.20.0 and later, measurementId is optional
const firebaseConfig = {
    apiKey: "AIzaSyDoKT2Kh0adRlQDAKKcymFulVp_2-vsiKg",
    authDomain: "kiducation-a0d40.firebaseapp.com",
    projectId: "kiducation-a0d40",
    storageBucket: "kiducation-a0d40.firebasestorage.app",
    messagingSenderId: "596941524882",
    appId: "1:596941524882:web:7b0edc324397db70ad7b4b",
    measurementId: "G-3ELPH4QL5T"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const analytics = getAnalytics(app);
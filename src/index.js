import "./main.css";
import { Elm } from "./Main.elm";
import * as serviceWorker from "./serviceWorker";
import firebase from "firebase/app";
import "firebase/analytics";
import "firebase/auth";
import "firebase/firestore";

// ここが異なるかも
const app = Elm.Main.init({
  node: document.getElementById("root"),
});

const firebaseConfig = {
  //各自のapiKey等を入力してください
};

// If you want your app to work offline and load faster, you can change
// unregister() to register() below. Note this comes with some pitfalls.
// Learn more about service workers: https://bit.ly/CRA-PWA
serviceWorker.unregister();

// firebaseの初期化
firebase.initializeApp(firebaseConfig);
const Googleprovider = new firebase.auth.GoogleAuthProvider();
const DB = firebase.firestore();

app.ports.signingInWithGoogle.subscribe((_) => {
  firebase
    .auth()
    .signInWithPopup(Googleprovider)
    .then((_) => {
      app.ports.validateAuthState.send("SignedIn");
    })
    .catch((error) => {
      app.ports.validateAuthState.send("SignedInWithError");
    });
});

app.ports.saveContents.subscribe((Contents) => {
  const user = firebase.auth().currentUser;
  const time = firebase.firestore.FieldValue.serverTimestamp();
  const ref = DB.collection("Test").doc(user.uid).collection("Contents").doc();
  ref
    .set(
      {
        Title: Contents.title,
        Content: Contents.content,
        timestamp: time,
      },
      { merge: true }
    )
    .then(() => {
      app.ports.validateFirestore.send("Pass");
    })
    .catch(() => {
      app.ports.validateFirestore.send("Fail");
    });
});

--module Main exposing (..)


port module Main exposing
    ( Model
    , Msg(..)
    , init
    , main
    , saveContents
    , signingInWithGoogle
    , update
    , validateAuthState
    , validateFirestore
    , view
    )

import Browser
import Html exposing (Html, button, div, h1, h2, input, text)
import Html.Attributes exposing (placeholder, value)
import Html.Events exposing (onClick, onInput)
import Json.Encode as Encode



---- PROGRAM ----


main : Program () Model Msg
main =
    Browser.element
        { view = view
        , init = \_ -> init
        , update = update
        , subscriptions = subscriptions
        }



--- PORTS ---


port signingInWithGoogle : () -> Cmd msg


port validateAuthState : (String -> msg) -> Sub msg


port saveContents : Encode.Value -> Cmd msg


port validateFirestore : (String -> msg) -> Sub msg



---- MODEL ----


type AuthState
    = SignedOut
    | SignedIn
    | SignedInWithError


type FirestoreState
    = Pass
    | Fail


type alias Contents =
    { title : String
    , content : String
    }


type alias Model =
    { authState : AuthState
    , firestoreState : FirestoreState
    , contents : Contents
    }


initialModel : Model
initialModel =
    { authState = SignedOut
    , firestoreState = Fail
    , contents =
        { title = ""
        , content = ""
        }
    }


init : ( Model, Cmd Msg )
init =
    ( initialModel, Cmd.none )



---- UPDATE ----


type AuthMsg
    = SignIn


type ChangedContentsMsg
    = TitleChanged String
    | ContentChanged String


type SaveMsg
    = SaveContent


type ValidateAuthStateMsg
    = ValidateAuthState String


type ValidateFirestoreMsg
    = ValidateFirestore String


type Msg
    = AuthMsg AuthMsg
    | ChangedContentsMsg ChangedContentsMsg
    | SaveMsg SaveMsg
    | ValidateAuthStateMsg ValidateAuthStateMsg
    | ValidateFirestoreMsg ValidateFirestoreMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg =
    case msg of
        AuthMsg tryToAuthMsg ->
            updateAuth tryToAuthMsg

        ChangedContentsMsg changedContentsMsg ->
            updateChangedContents changedContentsMsg

        SaveMsg saveMsg ->
            updateSaveContent saveMsg

        ValidateAuthStateMsg validateAuthMsg ->
            updateValidateAuth validateAuthMsg

        ValidateFirestoreMsg validateSaveContentsMsg ->
            updateValidateFirestoreState validateSaveContentsMsg


updateAuth : AuthMsg -> Model -> ( Model, Cmd Msg )
updateAuth msg model =
    case msg of
        SignIn ->
            ( model, signingInWithGoogle () )


updateChangedContents : ChangedContentsMsg -> Model -> ( Model, Cmd Msg )
updateChangedContents msg model =
    let
        contents =
            model.contents
    in
    case msg of
        TitleChanged title ->
            ( { model | contents = { contents | title = title } }
            , Cmd.none
            )

        ContentChanged content ->
            ( { model | contents = { contents | content = content } }
            , Cmd.none
            )


updateSaveContent : SaveMsg -> Model -> ( Model, Cmd Msg )
updateSaveContent msg model =
    case msg of
        SaveContent ->
            ( model, saveContents <| contentsInfoEncoder model )


contentsInfoEncoder : Model -> Encode.Value
contentsInfoEncoder model =
    Encode.object
        [ ( "title", Encode.string model.contents.title )
        , ( "content", Encode.string model.contents.content )
        ]


updateValidateAuth : ValidateAuthStateMsg -> Model -> ( Model, Cmd Msg )
updateValidateAuth msg model =
    case msg of
        ValidateAuthState authState ->
            case authState of
                "SignedOut" ->
                    ( { model | authState = SignedOut }
                    , Cmd.none
                    )

                "SignedIn" ->
                    ( { model | authState = SignedIn }
                    , Cmd.none
                    )

                "SignedInWithError" ->
                    ( { model | authState = SignedInWithError }
                    , Cmd.none
                    )

                _ ->
                    ( model
                    , Cmd.none
                    )


updateValidateFirestoreState : ValidateFirestoreMsg -> Model -> ( Model, Cmd Msg )
updateValidateFirestoreState msg model =
    case msg of
        ValidateFirestore contentsmsg ->
            case contentsmsg of
                "Fail" ->
                    ( { model | firestoreState = Fail }
                    , Cmd.none
                    )

                "Pass" ->
                    ( { model | firestoreState = Pass }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )



-- SUBSCRIPTIUONS --


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ validateAuthState ValidateAuthState
            |> Sub.map ValidateAuthStateMsg
        , validateFirestore ValidateFirestore
            |> Sub.map ValidateFirestoreMsg
        ]



---- VIEW ----


view : Model -> Html Msg
view model =
    div []
        [ h1 [] [ text "Firebase Firestore" ]
        , h2 [] [ text "-- SignIn --" ]
        , Html.map AuthMsg viewLoginButton
        , viewValidateSignIn model
        , h2 [] [ text "-- Enter the contents in Firestore --" ]
        , Html.map ChangedContentsMsg (viewTItle model)
        , Html.map ChangedContentsMsg (viewContents model)
        , Html.map SaveMsg viewSaveButton
        , viewValidateFirestore model
        ]


viewTItle : Model -> Html ChangedContentsMsg
viewTItle model =
    div []
        [ input
            [ onInput TitleChanged
            , value model.contents.title
            , placeholder "Title"
            ]
            []
        ]


viewContents : Model -> Html ChangedContentsMsg
viewContents model =
    div []
        [ input
            [ onInput ContentChanged
            , value model.contents.content
            , placeholder "Contents"
            ]
            []
        ]


viewLoginButton : Html AuthMsg
viewLoginButton =
    div []
        [ button [ onClick SignIn ] [ text "Google SignIn" ] ]


viewSaveButton : Html SaveMsg
viewSaveButton =
    div []
        [ button [ onClick SaveContent ] [ text "Save" ] ]


viewValidateSignIn : Model -> Html Msg
viewValidateSignIn model =
    case model.authState of
        SignedOut ->
            div []
                [ div [] [ text "SignIn Status: SignOut" ]
                ]

        SignedIn ->
            div []
                [ div [] [ text "SignIn Status: SiginIn" ] ]

        SignedInWithError ->
            div []
                [ div [] [ text "SignIn Status: ERROR" ] ]


viewValidateFirestore : Model -> Html Msg
viewValidateFirestore model =
    case model.firestoreState of
        Pass ->
            div []
                [ div [] [ text "Firestore Status: Pass" ]
                ]

        Fail ->
            div []
                [ div [] [ text "Firestore Status: Fail" ] ]

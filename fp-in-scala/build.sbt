name := "scala-training"

version := "1.0"

scalaVersion := "2.11.7"

val scalazVersion = "7.1.0"
val scalazStreamVersion = "0.8"

libraryDependencies += "org.specs2" %% "specs2-core" % "3.7.2" % "test"
libraryDependencies += "org.specs2" %% "specs2-gwt" % "3.7.2" % "test"
libraryDependencies += "org.specs2" %% "specs2-mock" % "3.7.2" % "test"

libraryDependencies ++= Seq(
  "org.scalaz" %% "scalaz-core" % scalazVersion,
  "org.scalaz" %% "scalaz-effect" % scalazVersion,
  "org.scalaz" %% "scalaz-typelevel" % scalazVersion,
  "org.scalaz" %% "scalaz-concurrent" % scalazVersion,
  "org.scalaz.stream" %% "scalaz-stream" % scalazStreamVersion,
  "org.scalaz" %% "scalaz-scalacheck-binding" % scalazVersion % "test"
)

scalacOptions += "-feature"

initialCommands in console := "import scalaz._, Scalaz._, stream._, Process._, process1._, scalaz.concurrent._"

scalacOptions in Test ++= Seq("-Yrangepos")
